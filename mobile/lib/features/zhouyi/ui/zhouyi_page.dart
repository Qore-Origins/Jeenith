// Copyright (c) 2026 Qore
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/platform_info.dart';
import '../../../core/history/history_store.dart';
import '../../../core/history/history_providers.dart';
import '../../../data/yijing/hexagram_texts.dart';
import '../../../data/yijing/trigrams.dart';
import '../../../shared/widgets/decorative_panel.dart';
import '../../../shared/widgets/dark_button.dart';
import '../../../shared/widgets/entrance_item.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../../shared/widgets/copy_result_button.dart';
import '../../../shared/widgets/share_result_button.dart';
import '../../../shared/widgets/svg_icon.dart';
import '../../../shared/widgets/tech_guide_overlay.dart';
import '../../../shared/widgets/ai_case_launch_button.dart';
import '../algorithm/divine.dart';
import 'hexagram_view.dart';

class ZhouyiPage extends ConsumerStatefulWidget {
  const ZhouyiPage({super.key});

  @override
  ConsumerState<ZhouyiPage> createState() => _ZhouyiPageState();
}

class _ZhouyiPageState extends ConsumerState<ZhouyiPage>
    with SingleTickerProviderStateMixin {
  ZhouyiResult? _result;
  HistoryEntry? _resultHistoryEntry;
  bool _busy = false;
  late final AnimationController _anim;
  ScrollController? _sheetCtrl;
  // 桌面端无 DraggableScrollableSheet，自建 controller；移动端复用 sheet 的。
  ScrollController? _ownCtrl;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (PlatformInfo.isDesktop) {
      _ownCtrl = ScrollController();
      _sheetCtrl = _ownCtrl; // 桌面端把自建 controller 暴露给 reset 复用
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRestore();
      _showGuide();
    });
  }

  /// 首次进入显示使用指引（只弹一次）。
  Future<void> _showGuide() =>
      showTechGuideOnce(context, 'zhouyi', '周易金钱卦 · 使用指引', const [
        GuideStep('起卦', '心中默念所问之事，点「摇卦」摇六次（金钱卦，三铜钱之和定阴阳），注意力集中于顶点时起卦最灵。'),
        GuideStep('本卦与变卦', '老阴(6)、老阳(9)为变爻——阳极生阴、阴极生阳，翻转后得「之卦」；无变爻则以本卦为占。'),
        GuideStep('卦辞爻辞', '无变爻看本卦卦辞；一个变爻看该爻爻辞；多个变爻看之卦卦辞。'),
        GuideStep('心诚则灵', '一念不生之际起卦最准，切忌反复摇卦。'),
      ]);

  /// v2.4.3：从历史记录恢复，按 extra 快照重建卦象（周易为随机起卦，存结果快照）。
  void _maybeRestore() {
    final restore = ref.read(pendingRestoreProvider);
    if (restore == null || restore.techId != 'zhouyi') return;
    final extra = restore.extra;
    ref.read(pendingRestoreProvider.notifier).state = null;
    if (extra == null) return;
    final linesData = extra['lines'] as List?;
    final benName = extra['benName'] as String?;
    if (linesData == null || benName == null) return;
    final lines = linesData.map((l) {
      final m = l as Map<String, dynamic>;
      return (yang: m['yang'] as bool, changing: m['changing'] as bool);
    }).toList();
    setState(() {
      _result = ZhouyiResult(
        benName: benName,
        bianName: extra['bianName'] as String?,
        upperName: extra['upperName'] as String,
        lowerName: extra['lowerName'] as String,
        changing: (extra['changing'] as List).cast<int>(),
        lines: lines,
      );
      _resultHistoryEntry = restore;
    });
    _anim.value = 1; // 跳过逐爻揭示，直接显示完整卦象
  }

  @override
  void dispose() {
    _ownCtrl?.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _onToss() {
    setState(() {
      _result = divine();
      _busy = true;
    });
    _anim.value = 0;
    if (_sheetCtrl?.hasClients ?? false) _sheetCtrl!.jumpTo(0);
  }

  void _onReset() {
    setState(() {
      _result = null;
      _resultHistoryEntry = null;
      _busy = false;
    });
    _anim.value = 0;
    if (_sheetCtrl?.hasClients ?? false) _sheetCtrl!.jumpTo(0);
  }

  void _onRevealed() {
    setState(() => _busy = false);
    _anim.forward(from: 0);
    final entry = HistoryEntry(
      id: HistoryStore.generateId(),
      techId: 'zhouyi',
      techName: '周易',
      time: DateTime.now(),
      summary: _result?.benName ?? '',
      detail: _buildCopyText(),
      extra: {
        'lines': _result?.lines
            .map((l) => {'yang': l.yang, 'changing': l.changing})
            .toList(),
        'benName': _result?.benName,
        'bianName': _result?.bianName,
        'upperName': _result?.upperName,
        'lowerName': _result?.lowerName,
        'changing': _result?.changing,
      },
    );
    setState(() => _resultHistoryEntry = entry);
    unawaited(HistoryStore.add(entry));
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final c = AppClr.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Column(
          children: [
            const Text('周　易', style: TextStyle(fontSize: AppFontSize.title)),
            Text(
              '金 钱 卦',
              style: TextStyle(
                fontSize: AppFontSize.micro,
                color: c.textSubtitle,
                letterSpacing: AppLetterSpacing.decorative,
              ),
            ),
          ],
        ),
      ),
      body: PlatformInfo.isDesktop
          ? _buildDesktopBody(r)
          : Stack(
              children: [
                // —— 卜算可视化（底层固定，位置上移完整可见）——
                Transform.translate(
                  offset: const Offset(0, -80),
                  child: HexagramView(lines: r?.lines, onDone: _onRevealed),
                ),
                // —— 交互与结果（上层，可拖拽覆盖；交互粘顶吸附）——
                Positioned.fill(
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.35,
                    minChildSize: 0.3,
                    maxChildSize: 1.0,
                    builder: (context, scrollController) {
                      _sheetCtrl = scrollController;
                      return Container(
                        decoration: BoxDecoration(
                          color: c.bg.withValues(alpha: 0.95),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.panel),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: c.gold.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            SliverToBoxAdapter(child: _buildDragHandle()),
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _PinHeaderDelegate(
                                child: _buildActionBar(r),
                              ),
                            ),
                            _buildResultSliver(r),
                            if (_resultHistoryEntry != null)
                              _buildAiLaunchSliver(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// 拖拽把手（仅移动端 sheet 用）。
  Widget _buildDragHandle() {
    final c = AppClr.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: c.gold.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.hairline),
        ),
      ),
    );
  }

  /// 交互区（摇卦/重置/复制/分享）—— pinned header 内容，移动/桌面共用。
  ///
  /// v2.10.3 竖线坍塌第 5 次修复：原单行 4 按钮 + Expanded(GoldButton) 在
  /// 320-411px 屏触发矛盾约束（其他按钮 minWidth 之和 > 可用宽度，Expanded
  /// 给 GoldButton width<88，ConstrainedBox(minWidth:88).enforce(tight(W<88))
  /// 产生 size=0/child=88 撕裂，release 模式渲染降级为竖线）。
  ///
  /// 改为 4 按钮 intrinsic 宽度单行 + FittedBox(scaleDown) 自适应：
  ///   - 大屏（≥480px）：4 按钮 intrinsic 总宽 < 可用宽，原尺寸居中，左右留白
  ///   - 小屏（<480px）：4 按钮 intrinsic 总宽 > 可用宽，整体等比缩小到一行容纳
  /// 不用 Expanded（避免 tight(W<88) 矛盾约束）；不用 SingleChildScrollView
  /// 横向滚动（嵌套 viewport 在 pinned SliverPersistentHeader 内会导致 hit test
  /// 时 sliver.geometry 为 null，抛 Null check operator 崩溃）。
  /// GoldButton 内部 LayoutBuilder 防御层仍保留作为兜底。同步 _PinHeaderDelegate
  /// extent 90 → 104 → 90（单行）。
  Widget _buildActionBar(ZhouyiResult? r) => Container(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
    color: AppClr.of(context).bg.withValues(alpha: 0.92),
    // minHeight 必须与 _PinHeaderDelegate 的 extent(90) 一致，否则 child 实际
    // 高度 < delegate extent(90) 会产生 paintExtent < layoutExtent 的异常
    // SliverGeometry，致后续 sliver 不被 layout、viewport paint 时空指针崩溃。
    constraints: const BoxConstraints(minHeight: 90),
    child: Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GoldButton(
              text: _busy ? '摇卦中…' : '摇卦',
              onPressed: _busy ? null : _onToss,
            ),
            const SizedBox(width: 8),
            DarkButton(
              icon: const SvgIcon('refresh'),
              text: '重置',
              onPressed: _busy ? null : _onReset,
            ),
            const SizedBox(width: 8),
            CopyResultButton(text: _buildCopyText(), enabled: r != null),
            const SizedBox(width: 8),
            ShareResultButton(
              boundaryKey: _boundaryKey,
              enabled: r != null,
              fallbackText: _buildCopyText(),
            ),
          ],
        ),
      ),
    ),
  );

  /// 结果列表 sliver —— 移动/桌面共用。
  /// 包裹 RepaintBoundary 以支持截图分享。
  /// RepaintBoundary 仅包裹卦象展示结果区，绝不包裹底部按钮（ActionBar）。
  Widget _buildResultSliver(ZhouyiResult? r) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
    sliver: SliverToBoxAdapter(
      child: RepaintBoundary(
        key: _boundaryKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _resultItems(r),
        ),
      ),
    ),
  );

  Widget _buildAiLaunchSliver() => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.large,
      0,
      AppSpacing.large,
      AppSpacing.xLarge,
    ),
    sliver: SliverToBoxAdapter(
      child: Center(
        child: AiCaseLaunchButton.fromHistoryEntry(_resultHistoryEntry!),
      ),
    ),
  );

  /// 桌面端布局：可视化（固定）+ 交互结果（滚轮滚动）。
  /// 桌面端鼠标拖拽不灵，弃用 DraggableScrollableSheet，改上下分栏。
  Widget _buildDesktopBody(ZhouyiResult? r) {
    final c = AppClr.of(context);
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: Center(
            child: HexagramView(lines: r?.lines, onDone: _onRevealed),
          ),
        ),
        Divider(height: 1, thickness: 1, color: c.gold.withValues(alpha: 0.5)),
        Expanded(
          child: CustomScrollView(
            controller: _sheetCtrl,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinHeaderDelegate(child: _buildActionBar(r)),
              ),
              _buildResultSliver(r),
              if (_resultHistoryEntry != null) _buildAiLaunchSliver(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _resultItems(ZhouyiResult? r) {
    final c = AppClr.of(context);
    if (r == null) {
      return [
        const SizedBox(height: 40),
        Center(
          child: Text('点击「摇卦」以金钱卦起占', style: TextStyle(color: c.textHint)),
        ),
      ];
    }
    final benXiang = '${xiang[r.upperName]}${xiang[r.lowerName]}';
    return [
      EntranceItem(
        animation: _anim,
        interval: const Interval(0.0, 0.30),
        child: Center(
          child: Text(
            r.benName,
            style: TextStyle(
              color: c.goldBright,
              fontSize: AppFontSize.ritualDisplay,
              fontWeight: AppFontWeight.bold,
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      EntranceItem(
        animation: _anim,
        interval: const Interval(0.10, 0.36),
        child: Center(
          child: Text(
            '$benXiang${r.benName}',
            style: TextStyle(
              color: c.gold,
              fontSize: AppFontSize.title,
              letterSpacing: AppLetterSpacing.decorative,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      EntranceItem(
        animation: _anim,
        interval: const Interval(0.22, 0.48),
        child: DecorativePanel(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _trigramChip('上卦', r.upperName),
              const SizedBox(width: 24),
              _trigramChip('下卦', r.lowerName),
            ],
          ),
        ),
      ),
      if (r.bianName != null) ...[
        const SizedBox(height: 12),
        EntranceItem(
          animation: _anim,
          interval: const Interval(0.38, 0.66),
          child: DecorativePanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '变爻 ${r.changing.map((i) => _posLabel(i)).join("、")} → 之卦 ${r.bianName}',
                  style: TextStyle(
                    color: c.changing,
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '老阴(6)/老阳(9)为变爻，阴极生阳、阳极生阴，得之卦。',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.caption,
                    height: AppLineHeight.body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ] else ...[
        const SizedBox(height: 12),
        EntranceItem(
          animation: _anim,
          interval: const Interval(0.38, 0.66),
          child: DecorativePanel(
            padding: const EdgeInsets.all(12),
            child: Text(
              '无变爻，以本卦卦象为占。',
              style: TextStyle(color: c.textBody, fontSize: AppFontSize.label),
            ),
          ),
        ),
      ],
      // —— 本卦卦辞 ——
      const SizedBox(height: 12),
      EntranceItem(
        animation: _anim,
        interval: const Interval(0.54, 0.80),
        child: _buildGuaCiCard(
          title: '本卦卦辞 · ${r.benName}',
          guaName: r.benName,
          titleColor: c.gold,
        ),
      ),
      // —— 变爻爻辞列表 ——
      for (final i in r.changing)
        EntranceItem(
          animation: _anim,
          interval: Interval(
            (0.62 + i * 0.04).clamp(0.0, 0.92),
            (0.86 + i * 0.02).clamp(0.0, 1.0),
          ),
          child: _buildYaoCiCard(r, i),
        ),
      // —— 变卦卦辞 ——
      if (r.bianName != null) ...[
        const SizedBox(height: 12),
        EntranceItem(
          animation: _anim,
          interval: const Interval(0.70, 0.92),
          child: _buildGuaCiCard(
            title: '之卦卦辞 · ${r.bianName}',
            guaName: r.bianName!,
            titleColor: c.changing,
          ),
        ),
      ],
    ];
  }

  /// 卦辞卡片（标题 + 原文 + 白话注解）。
  Widget _buildGuaCiCard({
    required String title,
    required String guaName,
    required Color titleColor,
  }) {
    final ci = HexagramTexts.guaCi(guaName) ?? '';
    final note = HexagramTexts.guaCiNote(guaName) ?? '';
    final c = AppClr.of(context);
    return DecorativePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          if (ci.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              ci,
              style: TextStyle(
                color: c.textBody,
                fontSize: AppFontSize.body,
                height: AppLineHeight.reading,
              ),
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note,
              style: TextStyle(
                color: c.textSubtitle,
                fontSize: AppFontSize.label,
                height: AppLineHeight.body,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 单个变爻爻辞卡片。
  Widget _buildYaoCiCard(ZhouyiResult r, int index) {
    final line = r.lines[index];
    final posName = HexagramTexts.posName(index, line.yang);
    final ci = HexagramTexts.yaoCi(r.benName, posName) ?? '';
    final note = HexagramTexts.yaoCiNote(r.benName, posName) ?? '';
    final c = AppClr.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecorativePanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '变爻 · $posName',
              style: TextStyle(
                color: c.changing,
                fontSize: AppFontSize.bodySmall,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            if (ci.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                ci,
                style: TextStyle(
                  color: c.textBody,
                  fontSize: AppFontSize.body,
                  height: AppLineHeight.reading,
                ),
              ),
            ],
            if (note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                note,
                style: TextStyle(
                  color: c.textSubtitle,
                  fontSize: AppFontSize.label,
                  height: AppLineHeight.body,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 生成详细结果文本（供复制）。
  String _buildCopyText() {
    final r = _result;
    if (r == null) return '';
    final sb = StringBuffer('【周易 · 金钱卦】\n');
    sb.writeln('时间：${DateTime.now().toString().substring(0, 19)}');
    sb.writeln(
      '本卦：${r.benName}（${xiang[r.upperName]}${xiang[r.lowerName]}${r.benName}）',
    );
    sb.writeln(
      '上卦：${r.upperName}${xiang[r.upperName]}  下卦：${r.lowerName}${xiang[r.lowerName]}',
    );
    sb.writeln('\n—— 六爻 ——');
    const pos = ['初', '二', '三', '四', '五', '上'];
    for (var i = 0; i < 6; i++) {
      final line = r.lines[i];
      final type = line.yang ? '阳' : '阴';
      final ch = line.changing ? '（变）' : '';
      sb.writeln('${pos[i]}爻：$type$ch');
    }
    if (r.bianName != null) {
      sb.writeln(
        '\n变爻：${r.changing.map((i) => pos[i]).join("、")} → 之卦：${r.bianName}',
      );
    } else {
      sb.writeln('\n无变爻，以本卦为占。');
    }
    // 卦辞爻辞
    final benCi = HexagramTexts.guaCi(r.benName);
    if (benCi != null && benCi.isNotEmpty) {
      sb.writeln('\n—— 本卦卦辞 ——');
      sb.writeln(benCi);
      final benNote = HexagramTexts.guaCiNote(r.benName);
      if (benNote != null && benNote.isNotEmpty) sb.writeln('注：$benNote');
    }
    for (final i in r.changing) {
      final line = r.lines[i];
      final posName = HexagramTexts.posName(i, line.yang);
      final ci = HexagramTexts.yaoCi(r.benName, posName);
      if (ci != null && ci.isNotEmpty) {
        sb.writeln('\n—— 变爻 $posName ——');
        sb.writeln(ci);
        final note = HexagramTexts.yaoCiNote(r.benName, posName);
        if (note != null && note.isNotEmpty) sb.writeln('注：$note');
      }
    }
    if (r.bianName != null) {
      final bianCi = HexagramTexts.guaCi(r.bianName!);
      if (bianCi != null && bianCi.isNotEmpty) {
        sb.writeln('\n—— 之卦卦辞 ——');
        sb.writeln(bianCi);
        final bianNote = HexagramTexts.guaCiNote(r.bianName!);
        if (bianNote != null && bianNote.isNotEmpty) sb.writeln('注：$bianNote');
      }
    }
    sb.writeln('\n—— 志极 Jeenith · 叩问本心 ——');
    return sb.toString();
  }

  Widget _trigramChip(String label, String name) {
    final c = AppClr.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: c.textSubtitle,
            fontSize: AppFontSize.caption,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$name${xiang[name]}',
          style: TextStyle(
            color: c.goldBright,
            fontSize: AppFontSize.title,
            fontWeight: AppFontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _posLabel(int i) => const ['初', '二', '三', '四', '五', '上'][i];
}

/// 交互区粘顶 delegate（pinned，固定高度）。
///
/// v2.10.3：extent 90 → 104（两行布局）→ 90（单行 + 横向滚动）。
/// 必须 == Container minHeight，否则会产生 paintExtent < layoutExtent 异常。
class _PinHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _PinHeaderDelegate({required this.child});

  @override
  double get minExtent => 90;
  @override
  double get maxExtent => 90;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      child;
  @override
  // child 依赖可变状态（结果 r / 摇卦 _busy），必须返回 true：page setState 后
  // 需 rebuild header，复制/分享按钮的 enabled 等参数才能随状态更新。曾误设
  // false 致 header 冻结在初始 r=null，表现为"已有结果仍无法点击复制/分享"。
  bool shouldRebuild(_) => true;
}
