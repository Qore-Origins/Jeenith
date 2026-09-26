// Copyright (c) 2026 Qore
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';
import 'ritual_animation.dart';

/// Zhouyi (金錢卦) ritual animation: six rounds of coin tossing form a hexagram.
///
/// Total duration ~5s ([AppAnimations.ritualZhouyi]). Progress 0.0 → 1.0:
///  - 6 rounds, each occupies 1/6 of total progress.
///  - Per round: first 60% three coins fall from the top while tumbling;
///    last 40% coins fade and one yao line forms in the bottom-up stack.
///  - At 0.95–1.0 the complete hexagram glows with a golden border and the
///    word "周易" appears faintly in the background.
class ZhouyiRitual extends RitualAnimation {
  /// 背景水印文字（周易默认「周易」，六爻纳甲复用时传「六爻」——同为金钱卦铜钱仪式）。
  final String watermark;
  const ZhouyiRitual({super.key, super.onCompleted, this.watermark = '周易'});

  @override
  RitualAnimationState<ZhouyiRitual> createState() => _ZhouyiRitualState();
}

class _ZhouyiRitualState extends RitualAnimationState<ZhouyiRitual> {
  late final AnimationController _ctrl;
  late final _RitualParams _p;

  @override
  void initState() {
    super.initState();
    _p = _RitualParams.random();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.ritualZhouyi),
    )..forward().then((_) => complete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ritualScaffold(
      AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _RitualPainter(_ctrl.value, _p, widget.watermark),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Pre-generated random parameters for one ritual run.
class _RitualParams {
  /// 6 rounds × 3 coins. `true` = heads (字, golden), `false` = tails (背, darker).
  final List<List<bool>> coins;

  /// 6 yao lines (bottom-up). `true` = yang (solid 阳爻), `false` = yin (broken 阴爻).
  final List<bool> yaos;

  /// Per-coin rotation offsets (18 values) for tumbling variety.
  final List<double> rotations;

  _RitualParams(this.coins, this.yaos, this.rotations);

  factory _RitualParams.random() {
    final rng = math.Random();
    final coins = <List<bool>>[];
    final yaos = <bool>[];
    final rotations = <double>[];
    for (var i = 0; i < 6; i++) {
      final faces = [rng.nextBool(), rng.nextBool(), rng.nextBool()];
      coins.add(faces);
      // 金钱卦: heads(字)=2, tails(背)=3. Sum 6/8 → yin, 7/9 → yang.
      // Equivalent: odd number of tails → yang (solid).
      final tails = faces.where((f) => !f).length;
      yaos.add(tails.isOdd);
    }
    for (var i = 0; i < 18; i++) {
      rotations.add(rng.nextDouble() * 2 * math.pi);
    }
    return _RitualParams(coins, yaos, rotations);
  }
}

class _RitualPainter extends CustomPainter {
  final double t; // overall progress 0..1
  final _RitualParams p;
  final String watermark;

  _RitualPainter(this.t, this.p, this.watermark);

  @override
  bool shouldRepaint(covariant _RitualPainter old) => true;

  /// Sub-interval progress within [a, b], clamped to 0..1.
  double _iv(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  /// easeIn (accelerating) for falling.
  double _easeIn(double x) => x * x;

  /// easeOut (decelerating) for landing / line appearance.
  double _easeOut(double x) => 1 - math.pow(1 - x, 3).toDouble();

  // —— Layout constants ——
  static const double _lineW = 120.0;
  static const double _lineH = 4.0;
  static const double _lineGap = 12.0;
  static const double _coinR = 18.0;
  static const double _coinSpacing = 50.0;
  static const double _fallEnd = 0.6; // within-round split: 60% fall, 40% form

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Stack geometry: lower portion of screen, centered.
    final stackHeight = 6 * _lineH + 5 * _lineGap;
    final stackBottomY = size.height * 0.82;
    final stackTopY = stackBottomY - stackHeight;

    final startY = -_coinR * 2; // coins start above the visible area

    // Faint "周易" watermark in background.
    _drawWatermark(canvas, size, _iv(0.0, 0.5));

    // Draw each round in order. Break when a round hasn't started yet.
    for (var k = 0; k < 6; k++) {
      final rT = _iv(k / 6.0, (k + 1) / 6.0);
      if (rT <= 0) break;

      // Line k sits at this y (bottom-up: k=0 at bottom).
      final lineY = stackBottomY - _lineH / 2 - k * (_lineH + _lineGap);

      if (rT < _fallEnd) {
        // Phase 1: three coins falling from the top.
        final fT = rT / _fallEnd;
        _drawFallingCoins(canvas, k, fT, cx, startY, lineY);
      } else {
        // Phase 2: coins fade, yao line forms.
        final lT = (rT - _fallEnd) / (1 - _fallEnd);
        // Coins linger and fade (first 30% of line phase).
        if (lT < 0.3) {
          _drawLandedCoins(canvas, k, cx, lineY, 1 - lT / 0.3);
        }
        // Yao line appears with easeOut.
        _drawYao(canvas, cx, lineY, p.yaos[k], _easeOut(lT.clamp(0.0, 1.0)));
      }
    }

    // Final glow on the complete hexagram.
    final glowT = _iv(0.95, 1.0);
    if (glowT > 0) {
      _drawHexagramGlow(canvas, cx, stackTopY, stackBottomY, glowT);
    }
  }

  /// Draw three tumbling coins of round [k] during their fall to [landY].
  void _drawFallingCoins(
    Canvas canvas,
    int k,
    double fT,
    double cx,
    double startY,
    double landY,
  ) {
    for (var i = 0; i < 3; i++) {
      final baseX = cx + (i - 1) * _coinSpacing;
      // Slight horizontal drift that peaks mid-fall and returns to zero.
      final dir = i == 0 ? -1.0 : (i == 2 ? 1.0 : 0.0);
      final drift = math.sin(fT * math.pi) * 3.0 * dir;
      final y = _fallY(fT, startY, landY);
      final rot = fT * 4 * math.pi + p.rotations[k * 3 + i];
      _drawCoin(canvas, Offset(baseX + drift, y), p.coins[k][i], rot, 1.0);
    }
  }

  /// Draw three landed coins at [landY] with fading [alpha].
  void _drawLandedCoins(
    Canvas canvas,
    int k,
    double cx,
    double landY,
    double alpha,
  ) {
    for (var i = 0; i < 3; i++) {
      final coinX = cx + (i - 1) * _coinSpacing;
      _drawCoin(canvas, Offset(coinX, landY), p.coins[k][i], 0.0, alpha);
    }
  }

  /// Vertical fall position: easeIn acceleration then a small bounce.
  double _fallY(double fT, double startY, double landY) {
    if (fT < 0.88) {
      final e = _easeIn(fT / 0.88);
      return ui.lerpDouble(startY, landY, e)!;
    } else {
      // Small overshoot settled with easeOut.
      final bT = (fT - 0.88) / 0.12;
      final e = _easeOut(bT);
      final overshoot = landY + 5;
      return ui.lerpDouble(overshoot, landY, e)!;
    }
  }

  /// Draw a single coin: golden heads (字) or darker tails (背), thin border.
  void _drawCoin(
    Canvas canvas,
    Offset pos,
    bool heads,
    double rotation,
    double alpha,
  ) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);

    final fill = heads
        ? AppColors.gold.withValues(alpha: 0.8 * alpha)
        : AppColors.panel.withValues(alpha: alpha);
    final border = AppColors.gold.withValues(alpha: 0.55 * alpha);

    canvas.drawCircle(Offset.zero, _coinR, Paint()..color = fill);
    canvas.drawCircle(
      Offset.zero,
      _coinR,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = border
        ..strokeWidth = 1.2,
    );

    // Character on the face.
    _drawText(
      canvas,
      heads ? '字' : '背',
      Offset.zero,
      TextStyle(
        color: heads
            ? AppColors.ritualDarkInk.withValues(alpha: alpha)
            : AppColors.goldBright.withValues(alpha: 0.7 * alpha),
        fontSize: _coinR * 0.85,
        fontWeight: AppFontWeight.bold,
      ),
    );
    canvas.restore();
  }

  /// Draw one yao line centered at [cx, y]. Yang = solid bar; yin = two bars.
  void _drawYao(Canvas canvas, double cx, double y, bool yang, double progress) {
    final alpha = progress.clamp(0.0, 1.0);
    if (alpha <= 0) return;
    // Slight scale-in from center for elegance.
    final scale = 0.6 + 0.4 * progress;

    final paint = Paint()
      ..color = AppColors.goldBright.withValues(alpha: alpha)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _lineH;

    if (yang) {
      // Solid line (阳爻).
      final halfW = (_lineW / 2) * scale;
      canvas.drawLine(Offset(cx - halfW, y), Offset(cx + halfW, y), paint);
    } else {
      // Broken line (阴爻): two bars with a gap in the middle.
      const gap = 10.0;
      final barW = (_lineW - gap) / 2; // 55
      final halfBar = (barW / 2) * scale;
      final midOffset = gap / 2 + barW / 2;
      // Left bar.
      canvas.drawLine(
        Offset(cx - midOffset - halfBar, y),
        Offset(cx - midOffset + halfBar, y),
        paint,
      );
      // Right bar.
      canvas.drawLine(
        Offset(cx + midOffset - halfBar, y),
        Offset(cx + midOffset + halfBar, y),
        paint,
      );
    }
  }

  /// Draw a faint "周易" watermark in the background.
  void _drawWatermark(Canvas canvas, Size size, double progress) {
    if (progress <= 0) return;
    _drawText(
      canvas,
      watermark,
      Offset(size.width / 2, size.height / 2),
      TextStyle(
        color: AppColors.gold.withValues(alpha: progress * 0.06),
        fontSize: size.shortestSide * 0.28,
        fontWeight: AppFontWeight.bold,
        letterSpacing: AppLetterSpacing.ritualDisplayWide,
      ),
    );
  }

  /// Draw a golden border glow around the complete hexagram stack.
  void _drawHexagramGlow(
    Canvas canvas,
    double cx,
    double stackTopY,
    double stackBottomY,
    double glowT,
  ) {
    final alpha = _easeOut(glowT);
    const padding = 18.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, (stackTopY + stackBottomY) / 2),
        width: _lineW + padding * 2,
        height: (stackBottomY - stackTopY) + padding * 2,
      ),
      const Radius.circular(AppRadius.small),
    );
    // Soft fill glow.
    canvas.drawRRect(
      rect,
      Paint()..color = AppColors.gold.withValues(alpha: alpha * 0.05),
    );
    // Golden border.
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.gold.withValues(alpha: alpha * 0.6)
        ..strokeWidth = 1.5,
    );
  }

  /// Draw centered text and dispose the TextPainter (project hard rule).
  void _drawText(Canvas canvas, String text, Offset pos, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    tp.dispose();
  }
}
