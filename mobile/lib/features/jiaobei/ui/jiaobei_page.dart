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
import '../../../shared/widgets/decorative_panel.dart';
import '../../../shared/widgets/dark_button.dart';
import '../../../shared/widgets/entrance_item.dart';
import '../../../shared/widgets/copy_result_button.dart';
import '../../../shared/widgets/share_result_button.dart';
import '../../../shared/widgets/ai_case_launch_button.dart';
import '../../../shared/widgets/gold_button.dart';
import '../algorithm/divine.dart';

class JiaobeiPage extends ConsumerStatefulWidget {
  const JiaobeiPage({super.key});

  @override
  ConsumerState<JiaobeiPage> createState() => _JiaobeiPageState();
}

class _JiaobeiPageState extends ConsumerState<JiaobeiPage>
    with SingleTickerProviderStateMixin {
  JiaoResult? _last;
  HistoryEntry? _resultHistoryEntry;
  final List<JiaoResult> _round = []; // 本轮（默认连掷三筊为一轮）
  int _shengCount = 0; // 累计圣筊数
  bool _busy = false;
  late final AnimationController _flip;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRestore());
  }

  /// v2.4.3：从历史记录恢复，按 extra 快照重建（掷筊为随机，存 last/round/shengCount）。
  void _maybeRestore() {
    final restore = ref.read(pendingRestoreProvider);
    if (restore == null || restore.techId != 'jiaobei') return;
    final extra = restore.extra;
    ref.read(pendingRestoreProvider.notifier).state = null;
    if (extra == null) return;
    final lastData = extra['last'] as Map<String, dynamic>?;
    final roundData = extra['round'] as List?;
    if (lastData == null || roundData == null) return;
    JiaoResult fromMap(Map<String, dynamic> m) => JiaoResult(
      m['p1Yang'] as bool,
      m['p2Yang'] as bool,
      JiaoType.values[m['type'] as int],
    );
    setState(() {
      _last = fromMap(lastData);
      _resultHistoryEntry = restore;
      _round.clear();
      _round.addAll(roundData.map((j) => fromMap(j as Map<String, dynamic>)));
      _shengCount = extra['shengCount'] as int? ?? 0;
    });
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  Future<void> _onToss() async {
    if (_busy) return;
    setState(() => _busy = true);
    _flip.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 360)); // 翻转中段出结果
    final r = divine();
    _round.add(r);
    if (r.type == JiaoType.sheng) _shengCount++;
    setState(() {
      _last = r;
      _busy = false;
    });
    final entry = HistoryEntry(
      id: HistoryStore.generateId(),
      techId: 'jiaobei',
      techName: '掷筊',
      time: DateTime.now(),
      summary: r.type.name,
      detail: _buildCopyText(),
      extra: {
        'last': {'p1Yang': r.p1Yang, 'p2Yang': r.p2Yang, 'type': r.type.index},
        'round': _round
            .map(
              (j) => {
                'p1Yang': j.p1Yang,
                'p2Yang': j.p2Yang,
                'type': j.type.index,
              },
            )
            .toList(),
        'shengCount': _shengCount,
      },
    );
    setState(() => _resultHistoryEntry = entry);
    unawaited(HistoryStore.add(entry));
  }

  void _onReset() {
    setState(() {
      _last = null;
      _resultHistoryEntry = null;
      _round.clear();
      _shengCount = 0;
    });
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
            const Text('掷　筊', style: TextStyle(fontSize: AppFontSize.title)),
            Text(
              '杯 筊 问 事',
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SizedBox(
            height: 180,
            child: Center(
              child: AnimatedBuilder(
                animation: _flip,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _jiaoPiece(_last?.p1Yang, _flip.value),
                    const SizedBox(width: 28),
                    _jiaoPiece(_last?.p2Yang, _flip.value),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_last != null)
            Center(
              child: Text(
                _last!.type.name,
                style: TextStyle(
                  color: _colorFor(_last!.type),
                  fontSize: AppFontSize.displaySmall,
                  fontWeight: AppFontWeight.bold,
                  letterSpacing: AppLetterSpacing.display,
                ),
              ),
            ),
          const SizedBox(height: 12),
          GoldButton(
            text: _busy ? '掷筊中…' : '掷筊',
            onPressed: _busy ? null : _onToss,
          ),
          const SizedBox(height: 8),
          DarkButton(text: '重置本轮', onPressed: _busy ? null : _onReset),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CopyResultButton(
                  text: _buildCopyText(),
                  enabled: _last != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShareResultButton(
                  boundaryKey: _boundaryKey,
                  enabled: _last != null,
                  fallbackText: _buildCopyText(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            key: _boundaryKey,
            child: RevealAnimation(
              enabled:
                  ref
                      .watch(configProvider)
                      .valueOrNull
                      ?.isAnimationEnabled('jiaobei', AnimationKind.reveal) ??
                  true,
              replayKey: _last,
              hero: DecorativePanel(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '本轮',
                          style: TextStyle(
                            color: c.textSubtitle,
                            fontSize: AppFontSize.label,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_round.length} 筊',
                          style: TextStyle(
                            color: c.goldBright,
                            fontSize: AppFontSize.bodySmall,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '圣筊',
                          style: TextStyle(
                            color: c.textSubtitle,
                            fontSize: AppFontSize.label,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_shengCount',
                          style: TextStyle(
                            color: c.gradeGreat,
                            fontSize: AppFontSize.bodySmall,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_last != null)
                      Text(
                        _last!.type.meaning,
                        style: TextStyle(
                          color: c.textBody,
                          fontSize: AppFontSize.label,
                          height: AppLineHeight.body,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '传统连掷三圣筊为确证。阳面为平面（凸背为阴）。',
                      style: TextStyle(
                        color: c.textHint,
                        fontSize: AppFontSize.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_resultHistoryEntry != null)
            Center(
              child: AiCaseLaunchButton.fromHistoryEntry(_resultHistoryEntry!),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _round.length; i++)
                EntranceItem(
                  animation: AlwaysStoppedAnimation(1),
                  interval: const Interval(0, 1),
                  child: _roundChip(_round[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _jiaoPiece(bool? yangUp, double flip) {
    final c = AppClr.of(context);
    // 翻转中：交替正反；落定后显示真实结果
    final showYang = _busy ? (flip * 6).floor().isOdd : (yangUp ?? true);
    // 阳面：鎏金亮（深色用 goldLight，浅色用更深的鎏金以保证对比度）
    // 阴面：暗褐（深色用紫黑褐，浅色用浅褐与浅色背景协调）
    return Transform.translate(
      offset: Offset(0, _busy ? -20 * (1 - flip.abs() * 2).abs() : 0),
      child: Container(
        width: 86,
        height: 56,
        decoration: BoxDecoration(
          color: showYang ? c.goldLight : c.ritualEarthDark,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: c.goldBright, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          showYang ? '阳' : '阴',
          style: TextStyle(
            // 阳面（亮鎏金底）：深棕文字（两模式通用）
            // 阴面（暗褐底）：浅金文字（深色）/深褐文字（浅色，与浅褐背景对比）
            color: showYang ? AppColors.ritualDarkInk : c.earthGlow,
            fontSize: AppFontSize.title,
            fontWeight: AppFontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _roundChip(JiaoResult r) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _colorFor(r.type).withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadius.small),
      border: Border.all(color: _colorFor(r.type).withValues(alpha: 0.5)),
    ),
    child: Text(
      r.type.name,
      style: TextStyle(color: _colorFor(r.type), fontSize: AppFontSize.label),
    ),
  );

  /// 生成详细结果文本（供复制）。
  String _buildCopyText() {
    final r = _last;
    if (r == null) return '';
    final sb = StringBuffer('【掷筊 · 杯筊问事】\n');
    sb.writeln('时间：${DateTime.now().toString().substring(0, 19)}');
    sb.writeln(
      '本次：${r.type.name}（片1${r.p1Yang ? "阳" : "阴"} 片2${r.p2Yang ? "阳" : "阴"}）',
    );
    sb.writeln('释义：${r.type.meaning}');
    sb.writeln('\n本轮：共 ${_round.length} 筊，其中圣筊 $_shengCount');
    sb.writeln('（传统连掷三圣筊为确证）');
    sb.writeln('\n—— 志极 Jeenith · 叩问本心 ——');
    return sb.toString();
  }

  Color _colorFor(JiaoType t) {
    final c = AppClr.of(context);
    return switch (t) {
      JiaoType.sheng => c.gradeGreat,
      JiaoType.xiao => c.goldBright,
      JiaoType.yin => c.gradeBad,
    };
  }
}
