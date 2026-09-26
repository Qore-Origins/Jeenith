// Copyright (c) 2026 Qore
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animation/reveal/reveal_animation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/config_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/history/history_store.dart';
import '../../../core/history/history_providers.dart';
import '../../../data/yijing/trigrams.dart';
import '../../../shared/widgets/decorative_panel.dart';
import '../../../shared/widgets/copy_result_button.dart';
import '../../../shared/widgets/share_result_button.dart';
import '../../../shared/widgets/ai_case_launch_button.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../../shared/widgets/tech_guide_overlay.dart';
import '../algorithm/divine.dart';
import '../data/najia_data.dart';
import '../data/liuyao_text.dart';

/// 爻题：阳「九」、阴「六」。初上两位在前，中四位于阴阳之后。
String yaoTitle(int i, bool yang) {
  final yinYang = yang ? '九' : '六';
  final pos = const ['初', '二', '三', '四', '五', '上'][i];
  return (i == 0 || i == 5) ? '$pos$yinYang' : '$yinYang$pos';
}

class LiuyaoPage extends ConsumerStatefulWidget {
  const LiuyaoPage({super.key});
  @override
  ConsumerState<LiuyaoPage> createState() => _LiuyaoPageState();
}

class _LiuyaoPageState extends ConsumerState<LiuyaoPage> {
  bool _isMale = true;
  int _topicIdx = 0; // 默认「求财谋利」
  LiuyaoResult? _r;
  HistoryEntry? _resultHistoryEntry;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRestore();
      _showGuide();
    });
  }

  /// 首次进入显示使用指引（只弹一次）。
  Future<void> _showGuide() =>
      showTechGuideOnce(context, 'liuyao', '六爻纳甲 · 使用指引', const [
        GuideStep('起卦', '先选「所测之事」（定用神）与性别，再摇六爻；金钱卦同周易，但断法以纳甲为主。'),
        GuideStep('纳甲排盘', '六爻配六亲（父母/兄弟/子孙/妻财/官鬼）+ 六神 + 世应，用神为所测之事对应的六亲。'),
        GuideStep('断辞要点', '用神旺衰看月日生克，发动之爻主事之动向；空亡/六冲六合/三合三刑为格局参考。'),
        GuideStep('旺衰吉凶', '用神得月日生扶为旺（吉），受克为衰（凶），空亡待出空方有作为。'),
      ]);

  /// v2.8.0：从历史记录恢复，按 extra 中的原始六爻快照精确复现。
  void _maybeRestore() {
    final restore = ref.read(pendingRestoreProvider);
    if (restore == null || restore.techId != 'liuyao') return;
    final extra = restore.extra;
    ref.read(pendingRestoreProvider.notifier).state = null;
    if (extra == null) return;
    final rawList = extra['raw'] as List?;
    final yongShen = extra['yongShen'] as String?;
    if (rawList == null || yongShen == null) return;
    final raw = rawList.map((l) {
      final m = l as Map<String, dynamic>;
      return (yang: m['yang'] as bool, changing: m['changing'] as bool);
    }).toList();
    final ti = extra['topicIdx'] as int?;
    final male = extra['isMale'] as bool? ?? true;
    setState(() {
      if (ti != null && ti >= 0 && ti < topics.length) _topicIdx = ti;
      _isMale = male;
      _r = divine(yongShen: yongShen, rawLines: raw);
      _resultHistoryEntry = restore;
    });
  }

  void _onDivine() {
    final topic = topics[_topicIdx];
    final yongShen = topic.yongShen(_isMale);
    final raw = rollLines();
    setState(() => _r = divine(yongShen: yongShen, rawLines: raw));
    FocusScope.of(context).unfocus();
    final entry = HistoryEntry(
      id: HistoryStore.generateId(),
      techId: 'liuyao',
      techName: '六爻',
      time: DateTime.now(),
      summary: _r?.benName ?? '',
      detail: _buildCopyText(),
      extra: {
        'topicIdx': _topicIdx,
        'isMale': _isMale,
        'yongShen': yongShen,
        'raw': raw
            .map((l) => {'yang': l.yang, 'changing': l.changing})
            .toList(),
      },
    );
    setState(() => _resultHistoryEntry = entry);
    unawaited(HistoryStore.add(entry));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Column(
          children: [
            const Text('六　爻', style: TextStyle(fontSize: AppFontSize.title)),
            Text(
              '纳 甲 断 卦',
              style: TextStyle(
                fontSize: AppFontSize.micro,
                color: c.textSubtitle,
                letterSpacing: AppLetterSpacing.decorative,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildInput(c),
          const SizedBox(height: 14),
          if (_r != null)
            RepaintBoundary(key: _boundaryKey, child: _buildResult(_r!)),
          if (_resultHistoryEntry != null)
            Center(
              child: AiCaseLaunchButton.fromHistoryEntry(_resultHistoryEntry!),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInput(AppClr c) {
    return DecorativePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '性别',
                style: TextStyle(
                  color: c.textBody,
                  fontSize: AppFontSize.label,
                ),
              ),
              const SizedBox(width: 10),
              _genderChip('男', true),
              const SizedBox(width: 6),
              _genderChip('女', false),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '所测之事',
            style: TextStyle(color: c.textBody, fontSize: AppFontSize.label),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < topics.length; i++) _topicChip(i, c),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '用神：${topics[_topicIdx].yongShen(_isMale)}',
            style: TextStyle(color: c.goldBright, fontSize: AppFontSize.label),
          ),
          const SizedBox(height: 12),
          GoldButton(text: '摇卦起占', onPressed: _onDivine),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CopyResultButton(
                  text: _buildCopyText(),
                  enabled: _r != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShareResultButton(
                  boundaryKey: _boundaryKey,
                  enabled: _r != null,
                  fallbackText: _buildCopyText(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genderChip(String label, bool male) {
    final c = AppClr.of(context);
    final selected = _isMale == male;
    return GestureDetector(
      onTap: () => setState(() => _isMale = male),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? c.gold.withValues(alpha: 0.18)
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.compactRound),
          border: Border.all(color: selected ? c.gold : c.goldBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c.goldBright : c.textBody,
            fontSize: AppFontSize.bodySmall,
            fontWeight: selected ? AppFontWeight.bold : AppFontWeight.regular,
          ),
        ),
      ),
    );
  }

  Widget _topicChip(int i, AppClr c) {
    final selected = _topicIdx == i;
    return GestureDetector(
      onTap: () => setState(() => _topicIdx = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? c.gold.withValues(alpha: 0.18)
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.compactRound),
          border: Border.all(color: selected ? c.gold : c.goldBorder),
        ),
        child: Text(
          topics[i].label,
          style: TextStyle(
            color: selected ? c.goldBright : c.textBody,
            fontSize: AppFontSize.label,
            fontWeight: selected ? AppFontWeight.bold : AppFontWeight.regular,
          ),
        ),
      ),
    );
  }

  /// 六冲/六合卦标记 chip。
  Widget _gejuChip(LiuyaoResult r, AppClr c) {
    final label = r.isLiuChong ? '六冲卦' : '六合卦';
    final color = r.isLiuChong ? c.changing : c.goldBright;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.compactRound),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppFontSize.label,
          fontWeight: AppFontWeight.bold,
          letterSpacing: AppLetterSpacing.label,
        ),
      ),
    );
  }

  Widget _buildResult(LiuyaoResult r) {
    final c = AppClr.of(context);
    final enabled =
        ref
            .watch(configProvider)
            .valueOrNull
            ?.isAnimationEnabled('liuyao', AnimationKind.reveal) ??
        true;
    return RevealAnimation(
      enabled: enabled,
      replayKey: r,
      hero: DecorativePanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              r.benName,
              style: TextStyle(
                color: c.goldBright,
                fontSize: AppFontSize.heroLarge,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${xiang[r.upperName]}${xiang[r.lowerName]}${r.benName}'
              ' · ${r.bagong.gong}宫${r.bagong.seqName}（${r.gongWuxing}）',
              style: TextStyle(
                color: c.gold,
                fontSize: AppFontSize.bodySmall,
                letterSpacing: AppLetterSpacing.label,
              ),
            ),
            if (r.isLiuChong || r.isLiuHe) ...[
              const SizedBox(height: 4),
              _gejuChip(r, c),
            ],
            const SizedBox(height: 6),
            Text(
              '日辰 ${r.dayGan}${r.dayZhi} · 月建${r.monthZhi} · 日空${r.dayKong.join("")}'
              ' · 用神「${r.yongShen}」${r.yongKong ? "（空）" : ""}',
              style: TextStyle(
                color: c.textBody,
                fontSize: AppFontSize.caption,
              ),
            ),
          ],
        ),
      ),
      sections: [
        Text(
          '◆ 六爻纳甲盘',
          style: TextStyle(
            color: c.gold,
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
            letterSpacing: AppLetterSpacing.label,
          ),
        ),
        _buildYaoTable(r, r.lines, bianMode: false),
        Text(
          '◆ 用神断辞',
          style: TextStyle(
            color: c.gold,
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
            letterSpacing: AppLetterSpacing.label,
          ),
        ),
        _buildJudgeCard(r, c),
        if (r.bianLines != null) ...[
          Text(
            '◆ 之卦 · ${r.bianName}',
            style: TextStyle(
              color: c.changing,
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.bold,
              letterSpacing: AppLetterSpacing.label,
            ),
          ),
          _buildYaoTable(r, r.bianLines!, bianMode: true),
        ],
        Text(
          '◆ 六亲 · 六神 释义',
          style: TextStyle(
            color: c.gold,
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
            letterSpacing: AppLetterSpacing.label,
          ),
        ),
        _buildLegend(c),
      ],
    );
  }

  /// 六爻表（自上爻至初爻倒序）。
  Widget _buildYaoTable(
    LiuyaoResult r,
    List<Yao> lines, {
    required bool bianMode,
  }) {
    return DecorativePanel(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        children: [
          for (var i = 5; i >= 0; i--) _buildYaoRow(r, lines, i, bianMode),
        ],
      ),
    );
  }

  Widget _buildYaoRow(LiuyaoResult r, List<Yao> lines, int i, bool bianMode) {
    final c = AppClr.of(context);
    final y = lines[i];
    final isYong = !bianMode && i == r.yongPos;
    final isShi = !bianMode && i == r.bagong.shi;
    final isYing = !bianMode && i == r.bagong.ying;
    // 本卦动爻位在变卦表中显示为「变」。
    final changed = bianMode && r.lines[i].changing;

    final tags = <Widget>[];
    if (isYong) tags.add(_tag('用', c.goldBright));
    if (isYong && r.yongKong) tags.add(_tag('空', c.changing));
    if (isShi) tags.add(_tag('世', c.fireGlow));
    if (isYing) tags.add(_tag('应', c.gold));
    if (y.changing) tags.add(_tag(y.yang ? '○' : '×', c.changing));
    if (changed) tags.add(_tag('变', c.changing));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              yaoTitle(i, y.yang),
              style: TextStyle(
                color: c.textMeta,
                fontSize: AppFontSize.label,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _yaoSymbol(y.yang, c),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Text(
                  y.liuqin,
                  style: TextStyle(
                    color: isYong ? c.goldBright : c.textPrimary,
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: isYong
                        ? AppFontWeight.bold
                        : AppFontWeight.regular,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${y.gan}${y.zhi}',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  zhiWuxing[y.zhi]!,
                  style: TextStyle(
                    color: c.textSubtitle,
                    fontSize: AppFontSize.micro,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              y.shenshou,
              style: TextStyle(
                color: c.textMeta,
                fontSize: AppFontSize.caption,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Row(mainAxisSize: MainAxisSize.min, children: tags),
        ],
      ),
    );
  }

  /// 阳爻一长横、阴爻两短横。
  Widget _yaoSymbol(bool yang, AppClr c) {
    if (yang) {
      return Container(width: 44, height: 4, color: c.gold);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 18, height: 4, color: c.gold),
        const SizedBox(width: 8),
        Container(width: 18, height: 4, color: c.gold),
      ],
    );
  }

  Widget _tag(String t, Color color) => Container(
    margin: const EdgeInsets.only(left: 3),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(AppRadius.tiny),
      border: Border.all(color: color.withValues(alpha: 0.6)),
    ),
    child: Text(
      t,
      style: TextStyle(
        color: color,
        fontSize: AppFontSize.micro,
        fontWeight: AppFontWeight.bold,
      ),
    ),
  );

  Widget _buildJudgeCard(LiuyaoResult r, AppClr c) {
    return DecorativePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.fire.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(color: c.fireGlow.withValues(alpha: 0.6)),
            ),
            child: Text(
              r.judgment,
              style: TextStyle(
                color: c.fireGlow,
                fontSize: AppFontSize.button,
                fontWeight: AppFontWeight.bold,
                height: AppLineHeight.body,
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final p in r.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '· ',
                    style: TextStyle(
                      color: c.gold,
                      fontSize: AppFontSize.label,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p,
                      style: TextStyle(
                        color: c.textBody,
                        fontSize: AppFontSize.label,
                        height: AppLineHeight.reading,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(AppClr c) {
    return DecorativePanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '六亲（以卦宫五行为「我」）',
            style: TextStyle(
              color: c.gold,
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          for (final lq in liuqinNames)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '$lq · ${liuqinMeaning[lq]}',
                style: TextStyle(
                  color: c.textBody,
                  fontSize: AppFontSize.caption,
                  height: AppLineHeight.body,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '六神（按日干起初爻顺布）',
            style: TextStyle(
              color: c.gold,
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          for (final s in liushenOrder)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '$s · ${liushenMeaning[s]}',
                style: TextStyle(
                  color: c.textBody,
                  fontSize: AppFontSize.caption,
                  height: AppLineHeight.body,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _buildCopyText() {
    final r = _r;
    if (r == null) return '';
    final sb = StringBuffer('【六爻 · 纳甲断卦】\n');
    sb.writeln('时间：${DateTime.now().toString().substring(0, 19)}');
    sb.writeln(
      '本卦：${r.benName}（${xiang[r.upperName]}${xiang[r.lowerName]}）'
      ' · ${r.bagong.gong}宫${r.bagong.seqName}（${r.gongWuxing}）',
    );
    sb.writeln(
      '日辰：${r.dayGan}${r.dayZhi} · 月建${r.monthZhi} · 用神「${r.yongShen}」',
    );
    sb.writeln('\n—— 六爻纳甲（自上而下）——');
    for (var i = 5; i >= 0; i--) {
      final y = r.lines[i];
      final marks = <String>[];
      if (i == r.yongPos) marks.add('用');
      if (i == r.bagong.shi) marks.add('世');
      if (i == r.bagong.ying) marks.add('应');
      if (y.changing) marks.add(y.yang ? '○' : '×');
      sb.writeln(
        '${yaoTitle(i, y.yang)}  ${y.liuqin} ${y.gan}${y.zhi}'
        '（${zhiWuxing[y.zhi]}） ${y.shenshou}${marks.isEmpty ? "" : " ${marks.join('·')}"}',
      );
    }
    sb.writeln('\n—— 断辞 ——');
    sb.writeln(r.judgment);
    for (final p in r.points) {
      sb.writeln('· $p');
    }
    if (r.bianLines != null) {
      sb.writeln('\n—— 之卦 ${r.bianName} ——');
      for (var i = 5; i >= 0; i--) {
        final y = r.bianLines![i];
        final ch = r.lines[i].changing ? ' 变' : '';
        sb.writeln(
          '${yaoTitle(i, y.yang)}  ${y.liuqin} ${y.gan}${y.zhi}'
          '（${zhiWuxing[y.zhi]}） ${y.shenshou}$ch',
        );
      }
    }
    sb.writeln('\n—— 志极 Jeenith · 叩问本心 ——');
    return sb.toString();
  }
}
