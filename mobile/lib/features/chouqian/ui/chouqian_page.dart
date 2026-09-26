// Copyright (c) 2026 Qore
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animation/reveal/reveal_animation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/config_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/history/history_store.dart';
import '../../../core/history/history_providers.dart';
import '../../../core/rng/rng_providers.dart';
import '../../../shared/widgets/decorative_panel.dart';
import '../../../shared/widgets/dark_button.dart';
import '../../../shared/widgets/copy_result_button.dart';
import '../../../shared/widgets/share_result_button.dart';
import '../../../shared/widgets/ai_case_launch_button.dart';
import '../../../shared/widgets/gold_button.dart';
import '../algorithm/divine.dart';

class ChouqianPage extends ConsumerStatefulWidget {
  const ChouqianPage({super.key});

  @override
  ConsumerState<ChouqianPage> createState() => _ChouqianPageState();
}

class _ChouqianPageState extends ConsumerState<ChouqianPage>
    with TickerProviderStateMixin {
  ChouqianResult? _last;
  HistoryEntry? _resultHistoryEntry;
  bool _busy = false;
  late final AnimationController _shake;
  late final AnimationController _fall;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fall = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRestore());
  }

  /// v2.4.3：从历史记录恢复，按 extra.stick 重建（不走摇签动画）。
  void _maybeRestore() {
    final restore = ref.read(pendingRestoreProvider);
    if (restore == null || restore.techId != 'chouqian') return;
    final stick = restore.extra?['stick'] as int?;
    ref.read(pendingRestoreProvider.notifier).state = null;
    if (stick == null) return;
    setState(() {
      _last = divine(stick);
      _resultHistoryEntry = restore;
    });
  }

  @override
  void dispose() {
    _shake.dispose();
    _fall.dispose();
    super.dispose();
  }

  Future<void> _onDraw() async {
    if (_busy) return;
    setState(() => _busy = true);
    _shake.forward(from: 0);
    // 摇签中段出签
    await Future.delayed(const Duration(milliseconds: 760));
    final entropy = await ref
        .read(trueRandomProvider)
        .generate(count: 1, vmax: stickCount);
    if (!mounted) return;
    final result = divine(entropy.numbers.first);
    setState(() {
      _last = result;
      _busy = false;
    });
    _fall.forward(from: 0);
    final entry = HistoryEntry(
      id: HistoryStore.generateId(),
      techId: 'chouqian',
      techName: '抽签',
      time: DateTime.now(),
      summary:
          '第${result.stick.number}签 · ${result.stick.title} · ${result.stick.grade.label}',
      detail: _buildCopyText(result),
      extra: {'stick': result.stick.number},
    );
    setState(() => _resultHistoryEntry = entry);
    unawaited(HistoryStore.add(entry));
  }

  void _onReset() {
    setState(() {
      _last = null;
      _resultHistoryEntry = null;
      _busy = false;
    });
    _shake.value = 0;
    _fall.value = 0;
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
            const Text('抽　签', style: TextStyle(fontSize: AppFontSize.title)),
            Text(
              '百 签 问 运',
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
            height: 220,
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_shake, _fall]),
                builder: (context, _) => _buildHolder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_last != null)
            Center(
              child: Text(
                '第 ${_last!.stick.number} 签',
                style: TextStyle(
                  color: c.goldBright,
                  fontSize: AppFontSize.metric,
                  fontWeight: AppFontWeight.bold,
                  letterSpacing: AppLetterSpacing.decorative,
                ),
              ),
            ),
          const SizedBox(height: 12),
          GoldButton(
            text: _busy ? '摇签中…' : '摇签',
            onPressed: _busy ? null : _onDraw,
          ),
          const SizedBox(height: 8),
          DarkButton(text: '再抽一签', onPressed: _busy ? null : _onReset),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CopyResultButton(
                  text: _buildCopyText(_last),
                  enabled: _last != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShareResultButton(
                  boundaryKey: _boundaryKey,
                  enabled: _last != null,
                  fallbackText: _buildCopyText(_last),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_last != null)
            RepaintBoundary(key: _boundaryKey, child: _buildResult(_last!)),
          if (_resultHistoryEntry != null)
            Center(
              child: AiCaseLaunchButton.fromHistoryEntry(_resultHistoryEntry!),
            ),
        ],
      ),
    );
  }

  /// 竹签筒：摇动时左右摆动，落签时一根竹签从筒中升起。
  Widget _buildHolder() {
    final c = AppClr.of(context);
    // 摇摆：sin(8π * t) * (1 - t) 阻尼振荡
    final t = _shake.value;
    final swing = _busy ? math.sin(t * math.pi * 8) * (1 - t) * 0.18 : 0.0;
    // 落签：fall.value 0→1
    final fallProgress = _last != null ? _fall.value : 0.0;

    return Transform.rotate(
      angle: swing,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 筒身：深色用紫黑褐，浅色用浅褐与浅色背景协调
          Container(
            width: 110,
            height: 170,
            decoration: BoxDecoration(
              color: c.ritualEarthDark,
              borderRadius: BorderRadius.circular(AppRadius.dialog),
              border: Border.all(color: c.goldBright, width: 2),
              boxShadow: [
                BoxShadow(
                  color: c.gold.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _SticksPainter(
                fallProgress: fallProgress,
                busy: _busy,
                clr: c,
              ),
              size: const Size(110, 170),
            ),
          ),
          // 筒口装饰：稍亮一档褐色
          Positioned(
            top: 0,
            child: Container(
              width: 110,
              height: 16,
              decoration: BoxDecoration(
                color: c.ritualEarthLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.dialog),
                ),
                border: Border.all(color: c.goldBright, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(ChouqianResult r) {
    final stick = r.stick;
    final gradeColor = _colorForGrade(stick.grade);
    final c = AppClr.of(context);
    final enabled =
        ref
            .watch(configProvider)
            .valueOrNull
            ?.isAnimationEnabled('chouqian', AnimationKind.reveal) ??
        true;
    return DecorativePanel(
      padding: const EdgeInsets.all(16),
      child: RevealAnimation(
        enabled: enabled,
        replayKey: r,
        hero: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(color: gradeColor.withValues(alpha: 0.6)),
            ),
            child: Text(
              stick.grade.label,
              style: TextStyle(
                color: gradeColor,
                fontSize: AppFontSize.title,
                fontWeight: AppFontWeight.bold,
                letterSpacing: AppLetterSpacing.display,
              ),
            ),
          ),
        ),
        sections: [
          Center(
            child: Text(
              stick.title,
              style: TextStyle(
                color: c.goldBright,
                fontSize: AppFontSize.metric,
                fontWeight: AppFontWeight.bold,
                letterSpacing: AppLetterSpacing.ritual,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: c.bgMid.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(color: c.goldBorder),
            ),
            child: Text(
              stick.poem,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: AppFontSize.button,
                height: AppLineHeight.ritual,
                letterSpacing: AppLetterSpacing.subtle,
              ),
            ),
          ),
          _sectionLabel('解曰'),
          Text(
            stick.interpretation,
            style: TextStyle(
              color: c.textBody,
              fontSize: AppFontSize.bodySmall,
              height: AppLineHeight.reading,
            ),
          ),
          _sectionLabel('详注'),
          Text(
            stick.detail,
            style: TextStyle(
              color: c.textMeta,
              fontSize: AppFontSize.label,
              height: AppLineHeight.reading,
              letterSpacing: AppLetterSpacing.subtle,
            ),
          ),
          Center(
            child: Text(
              '${r.time.toString().substring(0, 19)} 抽得',
              style: TextStyle(
                color: c.textHint,
                fontSize: AppFontSize.caption,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final c = AppClr.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 3, height: 14, color: c.gold),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: c.goldBright,
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.bold,
              letterSpacing: AppLetterSpacing.label,
            ),
          ),
        ],
      ),
    );
  }

  /// 生成详细结果文本（供复制）。
  String _buildCopyText(ChouqianResult? r) {
    if (r == null) return '';
    final s = r.stick;
    final sb = StringBuffer('【抽签 · 百签问运】\n');
    sb.writeln('时间：${r.time.toString().substring(0, 19)}');
    sb.writeln('签号：第 ${s.number} 签');
    sb.writeln('签题：${s.title}');
    sb.writeln('等级：${s.grade.label}');
    sb.writeln('\n签诗：');
    sb.writeln(s.poem);
    sb.writeln('\n解曰：${s.interpretation}');
    sb.writeln('详注：${s.detail}');
    sb.writeln('\n—— 志极 Jeenith · 叩问本心 ——');
    return sb.toString();
  }

  Color _colorForGrade(StickGrade g) {
    final c = AppClr.of(context);
    return switch (g) {
      StickGrade.shangShang => c.gradeGreat,
      StickGrade.shang => c.gradeGood,
      StickGrade.zhong => c.gradeSteady,
      StickGrade.xia => c.gradeRough,
      StickGrade.xiaXia => c.gradeBad,
    };
  }
}

/// 签筒内竹签绘制：忙碌时摇晃，落签时一支升起。
class _SticksPainter extends CustomPainter {
  final double fallProgress;
  final bool busy;
  final AppClr clr;

  _SticksPainter({
    required this.fallProgress,
    required this.busy,
    required this.clr,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // 签筒内的竹签（背景一束）
    final stickPaint = Paint()
      ..color = clr.gold
      ..style = PaintingStyle.fill;
    final tipPaint = Paint()
      ..color = clr.goldBright
      ..style = PaintingStyle.fill;

    // 后排多根签
    final backSticks = [
      Offset(w * 0.25, h * 0.18),
      Offset(w * 0.40, h * 0.12),
      Offset(w * 0.55, h * 0.10),
      Offset(w * 0.70, h * 0.16),
      Offset(w * 0.85, h * 0.22),
    ];
    for (final p in backSticks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p, width: 6, height: 90),
          const Radius.circular(AppRadius.tiny),
        ),
        stickPaint,
      );
      canvas.drawCircle(p + Offset(0, -48), 3.5, tipPaint);
    }

    // 前排落出的那一根签
    if (fallProgress > 0) {
      final rise = fallProgress * 60; // 升起 60 像素
      final frontX = w * 0.5;
      final frontY = h * 0.3 - rise;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(frontX, frontY),
            width: 8,
            height: 110,
          ),
          const Radius.circular(AppRadius.compact),
        ),
        Paint()..color = clr.goldBright,
      );
      // 签头红色装饰
      canvas.drawCircle(
        Offset(frontX, frontY - 58),
        5,
        Paint()..color = clr.fire,
      );
      // 签号
      final tp = TextPainter(
        text: TextSpan(
          text: '签',
          style: TextStyle(
            color: clr.textHighlight,
            fontSize: AppFontSize.footnote,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(frontX - tp.width / 2, frontY - 62));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _SticksPainter old) =>
      fallProgress != old.fallProgress || busy != old.busy || clr != old.clr;
}
