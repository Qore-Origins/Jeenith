// Copyright (c) 2026 Qore
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';
import 'ritual_animation.dart';

/// 24 mountains of the Feng Shui compass, starting from North (top), clockwise.
const List<String> _mountains = [
  '壬', '子', '癸', '丑', '艮', '寅',
  '甲', '卯', '乙', '辰', '巽', '巳',
  '丙', '午', '丁', '未', '坤', '申',
  '庚', '酉', '辛', '戌', '乾', '亥',
];

/// 8 trigrams (Later Heaven Bagua) with compass angle and Unicode symbol.
class _TrigramInfo {
  final double degrees;
  final String symbol;
  const _TrigramInfo(this.degrees, this.symbol);
}

const List<_TrigramInfo> _trigrams = [
  _TrigramInfo(0, '☵'),   // 坎 Kan — North
  _TrigramInfo(45, '☶'),  // 艮 Gen — NE
  _TrigramInfo(90, '☳'),  // 震 Zhen — East
  _TrigramInfo(135, '☴'), // 巽 Xun — SE
  _TrigramInfo(180, '☲'), // 离 Li — South
  _TrigramInfo(225, '☷'),  // 坤 Kun — SW
  _TrigramInfo(270, '☱'), // 兑 Dui — West
  _TrigramInfo(315, '☰'),  // 乾 Qian — NW
];

/// Feng Shui compass (风水罗盘) ritual animation.
///
/// Simulates a compass needle scanning from North to a random target heading,
/// with 24 mountains lighting up sequentially. Total duration 4 s
/// ([AppAnimations.ritualLuopan]), progress 0.0 → 1.0:
///
///  1. **0.00–0.10** — Dark background. The compass dial circle draws
///     progressively (arc 0° → 360°, like a brush stroke).
///  2. **0.10–0.20** — Needle appears at North (pointing up, 0°). Gold
///     diamond shape with center pin.
///  3. **0.20–0.60** — Needle rapidly rotates (3 full turns, easeOut
///     deceleration) and settles on a random target angle. Mountains light
///     up as the needle sweeps past them (0.25–0.60).
///  4. **0.60–0.75** — Needle stabilizes at target. Golden radial glow from
///     the needle tip. The target mountain (closest to needle direction)
///     gets a bright highlight.
///  5. **0.75–0.90** — Cross-hair lines draw through center. Inner ring
///     draws. 8 trigram symbols appear at cardinal/intercardinal positions.
///  6. **0.90–1.00** — The entire compass glows. Text "风水罗盘" fades in
///     at the bottom.
class LuopanRitual extends RitualAnimation {
  const LuopanRitual({super.key, super.onCompleted});

  @override
  RitualAnimationState<LuopanRitual> createState() => _LuopanRitualState();
}

class _LuopanRitualState extends RitualAnimationState<LuopanRitual> {
  late final AnimationController _ctrl;
  late final double _targetAngle;

  @override
  void initState() {
    super.initState();
    _targetAngle = math.Random().nextDouble() * 2 * math.pi;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.ritualLuopan),
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
          painter: _LuopanPainter(_ctrl.value, _targetAngle),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Painter for the Feng Shui compass ritual. Draws all six phases onto the
/// canvas based on the global progress [t] (0.0–1.0) and the randomized
/// [targetAngle].
class _LuopanPainter extends CustomPainter {
  final double t;
  final double targetAngle;

  _LuopanPainter(this.t, this.targetAngle);

  // ── Layout constants (as ratios of R) ──
  static const double _mountainRadiusRatio = 0.82;
  static const double _trigramRadiusRatio = 0.62;
  static const double _innerRingRatio = 0.45;
  static const double _needleLengthRatio = 0.8;
  static const double _needleHalfWidth = 4.0;
  static const double _centerPinRadius = 5.0;
  static const double _mountainFontSize = 11.0;
  static const double _trigramFontSize = 14.0;

  @override
  bool shouldRepaint(covariant _LuopanPainter old) => true;

  /// Sub-interval progress within [a, b], clamped to 0..1.
  double _iv(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  /// easeOut (decelerating): 1 - (1 - x)^3.
  double _easeOut(double x) => 1 - math.pow(1 - x, 3).toDouble();

  /// Normalize an angle to [0, 2π).
  double _normalize(double angle) {
    final r = angle % (2 * math.pi);
    return r < 0 ? r + 2 * math.pi : r;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final R = math.min(size.width, size.height) * 0.36;

    // Phase 1: Dial circle (drawn progressively, stays visible).
    _drawDialCircle(canvas, cx, cy, R);

    // Phase 5: Cross-hairs and inner ring (background elements).
    _drawCrosshairsAndRing(canvas, cx, cy, R);

    // Phase 5: Trigram symbols.
    _drawTrigrams(canvas, cx, cy, R);

    // Phase 3: 24 mountains (dim → lit as needle sweeps).
    _drawMountains(canvas, cx, cy, R);

    // Phase 4: Target mountain highlight + needle tip glow.
    _drawTargetHighlight(canvas, cx, cy, R);
    _drawTipGlow(canvas, cx, cy, R);

    // Phases 2–4: The needle itself (on top of rings/mountains).
    _drawNeedle(canvas, cx, cy, R);

    // Phase 6: Full compass glow overlay.
    _drawFullGlow(canvas, cx, cy, R);

    // Phase 6: Title text.
    _drawTitle(canvas, cx, cy, R);
  }

  // ───────────────────── Phase 1: Dial Circle ─────────────────────

  /// Draws the compass dial: a subtle fill plus a stroke arc that grows from
  /// 0° to 360° starting at North (top).
  void _drawDialCircle(Canvas canvas, double cx, double cy, double R) {
    final dialT = _iv(0.0, 0.10);
    if (dialT <= 0) return;

    // Subtle fill (full circle once started).
    canvas.drawCircle(
      Offset(cx, cy),
      R,
      Paint()..color = AppColors.gold.withValues(alpha: 0.03),
    );

    // Arc stroke drawn progressively from North (top), clockwise.
    final sweep = dialT * 2 * math.pi;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: R);
    canvas.drawArc(
      rect,
      -math.pi / 2, // start at top (North)
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.gold
        ..strokeWidth = 2,
    );
  }

  // ────────────────── Phase 5: Cross-hairs + Ring ─────────────────

  /// Draws horizontal and vertical cross-hair lines through the center,
  /// plus the inner ring circle — all growing progressively.
  void _drawCrosshairsAndRing(Canvas canvas, double cx, double cy, double R) {
    final drawT = _iv(0.75, 0.90);
    if (drawT <= 0) return;

    final e = _easeOut(drawT);
    final halfLine = R * 0.9 * e;
    final crossColor = AppColors.gold.withValues(alpha: 0.3 * drawT);
    final crossPaint = Paint()
      ..color = crossColor
      ..strokeWidth = 1;

    // Horizontal cross-hair.
    canvas.drawLine(Offset(cx - halfLine, cy), Offset(cx + halfLine, cy), crossPaint);
    // Vertical cross-hair.
    canvas.drawLine(Offset(cx, cy - halfLine), Offset(cx, cy + halfLine), crossPaint);

    // Inner ring (arc drawn progressively from North).
    final innerR = R * _innerRingRatio;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: innerR),
      -math.pi / 2,
      drawT * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.gold.withValues(alpha: 0.4 * drawT)
        ..strokeWidth = 1,
    );
  }

  // ───────────────────── Phase 5: Trigrams ────────────────────────

  /// Draws the 8 trigram symbols at cardinal/intercardinal positions,
  /// staggered fade-in.
  void _drawTrigrams(Canvas canvas, double cx, double cy, double R) {
    final rT = R * _trigramRadiusRatio;

    for (var i = 0; i < 8; i++) {
      final startT = 0.75 + i * 0.018;
      final triT = _iv(startT, startT + 0.10);
      if (triT <= 0) continue;

      final angle = _trigrams[i].degrees * math.pi / 180;
      final px = cx + rT * math.sin(angle);
      final py = cy - rT * math.cos(angle);

      _drawText(
        canvas,
        _trigrams[i].symbol,
        Offset(px, py),
        TextStyle(
          color: AppColors.gold.withValues(alpha: 0.7 * triT),
          fontSize: _trigramFontSize,
        ),
      );
    }
  }

  // ───────────────────── Phase 3: Mountains ───────────────────────

  /// Draws the 24 mountains around the dial. Each starts dim, then lights up
  /// to bright gold when the needle's sweep has passed it.
  void _drawMountains(Canvas canvas, double cx, double cy, double R) {
    final appearT = _iv(0.15, 0.25);
    if (appearT <= 0) return;

    final lightProg = _iv(0.25, 0.60);
    final startNorm = _normalize(targetAngle);
    final rM = R * _mountainRadiusRatio;

    for (var i = 0; i < 24; i++) {
      final mountainAngle = i * math.pi / 12; // clockwise from North
      // Angular distance from sweep start to this mountain, in the sweep
      // direction (counter-clockwise = decreasing angle).
      final d = (startNorm - mountainAngle + 2 * math.pi) % (2 * math.pi);
      final litThreshold = d / (2 * math.pi);
      final isLit = lightProg >= litThreshold;

      final px = cx + rM * math.sin(mountainAngle);
      final py = cy - rM * math.cos(mountainAngle);

      _drawText(
        canvas,
        _mountains[i],
        Offset(px, py),
        TextStyle(
          color: isLit
              ? AppColors.goldBright
              : AppColors.textHint.withValues(alpha: appearT * 0.5),
          fontSize: _mountainFontSize,
          fontWeight: isLit ? AppFontWeight.bold : AppFontWeight.regular,
        ),
      );
    }
  }

  // ─────────────── Phase 4: Target Mountain Highlight ──────────────

  /// Brightens the mountain closest to the needle's final target direction.
  void _drawTargetHighlight(Canvas canvas, double cx, double cy, double R) {
    final highlightT = _iv(0.60, 0.75);
    if (highlightT <= 0) return;

    final targetNorm = _normalize(targetAngle);
    final targetIdx = (targetNorm / (math.pi / 12)).round() % 24;
    final mountainAngle = targetIdx * math.pi / 12;
    final rM = R * _mountainRadiusRatio;

    final px = cx + rM * math.sin(mountainAngle);
    final py = cy - rM * math.cos(mountainAngle);

    // Radial glow halo around the target mountain.
    const glowRadius = 16.0;
    canvas.drawCircle(
      Offset(px, py),
      glowRadius,
      Paint()
        ..shader = RadialGradient(colors: [
          AppColors.goldBright.withValues(alpha: highlightT * 0.6),
          AppColors.goldBright.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: Offset(px, py), radius: glowRadius)),
    );

    // Re-draw the mountain text with extra brightness and size.
    _drawText(
      canvas,
      _mountains[targetIdx],
      Offset(px, py),
      TextStyle(
        color: AppColors.goldBright.withValues(alpha: highlightT),
        fontSize: _mountainFontSize + 2,
        fontWeight: AppFontWeight.bold,
      ),
    );
  }

  // ───────────────── Phase 4: Needle Tip Glow ─────────────────────

  /// Emits a golden radial glow from the needle tip at the target direction.
  void _drawTipGlow(Canvas canvas, double cx, double cy, double R) {
    final glowT = _iv(0.60, 0.75);
    if (glowT <= 0) return;

    final halfLen = R * _needleLengthRatio / 2;
    // Tip position: compass angle → canvas coordinates.
    final tipX = cx + halfLen * math.sin(targetAngle);
    final tipY = cy - halfLen * math.cos(targetAngle);

    final glowRadius = R * 0.3;
    canvas.drawCircle(
      Offset(tipX, tipY),
      glowRadius,
      Paint()
        ..shader = RadialGradient(colors: [
          AppColors.goldBright.withValues(alpha: glowT * 0.5),
          AppColors.gold.withValues(alpha: glowT * 0.2),
          AppColors.gold.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: Offset(tipX, tipY), radius: glowRadius)),
    );
  }

  // ─────────────── Phases 2–4: The Needle ──────────────────────────

  /// Draws the compass needle: a gold diamond (north half bright, south half
  /// darker) with a center pin. Angle and alpha are phase-dependent.
  void _drawNeedle(Canvas canvas, double cx, double cy, double R) {
    if (t < 0.10) return;

    double needleAngle;
    double needleAlpha;

    if (t < 0.20) {
      // Phase 2: appear at North (0°).
      needleAngle = 0;
      needleAlpha = _iv(0.10, 0.20);
    } else if (t < 0.60) {
      // Phase 3: rotate with easeOut deceleration (3 full turns + target).
      final p = _iv(0.20, 0.60);
      final e = _easeOut(p);
      needleAngle = targetAngle + (1 - e) * 3 * 2 * math.pi;
      needleAlpha = 1.0;
    } else {
      // Phase 4+: stabilized at target angle.
      needleAngle = targetAngle;
      needleAlpha = 1.0;
    }

    final halfLen = R * _needleLengthRatio / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(needleAngle);

    // North half (tip): bright gold.
    final northPath = Path()
      ..moveTo(0, -halfLen)
      ..lineTo(_needleHalfWidth, 0)
      ..lineTo(-_needleHalfWidth, 0)
      ..close();
    canvas.drawPath(
      northPath,
      Paint()..color = AppColors.goldBright.withValues(alpha: needleAlpha),
    );

    // South half (tail): darker gold.
    final southPath = Path()
      ..moveTo(0, halfLen)
      ..lineTo(_needleHalfWidth, 0)
      ..lineTo(-_needleHalfWidth, 0)
      ..close();
    canvas.drawPath(
      southPath,
      Paint()
        ..color = AppColors.darker(AppColors.gold, 0.4)
            .withValues(alpha: needleAlpha),
    );

    // Center pin.
    canvas.drawCircle(
      Offset.zero,
      _centerPinRadius,
      Paint()..color = AppColors.gold.withValues(alpha: needleAlpha),
    );

    canvas.restore();
  }

  // ───────────────── Phase 6: Full Compass Glow ───────────────────

  /// A subtle golden radial glow that makes the entire compass shine.
  void _drawFullGlow(Canvas canvas, double cx, double cy, double R) {
    final glowT = _iv(0.90, 1.00);
    if (glowT <= 0) return;

    final e = _easeOut(glowT);
    final glowRadius = R * 1.3;

    // Soft radial gradient emanating from the center.
    canvas.drawCircle(
      Offset(cx, cy),
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0),
            AppColors.gold.withValues(alpha: e * 0.08),
            AppColors.gold.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowRadius)),
    );

    // Brighten the dial circle stroke.
    canvas.drawCircle(
      Offset(cx, cy),
      R,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.goldBright.withValues(alpha: e * 0.6)
        ..strokeWidth = 2,
    );
  }

  // ───────────────────── Phase 6: Title ───────────────────────────

  /// Fades in the text "风水罗盘" below the compass.
  void _drawTitle(Canvas canvas, double cx, double cy, double R) {
    final titleT = _iv(0.90, 1.00);
    if (titleT <= 0) return;

    _drawText(
      canvas,
      '风水罗盘',
      Offset(cx, cy + R + 40),
      TextStyle(
        color: AppColors.goldBright.withValues(alpha: titleT),
        fontSize: AppFontSize.metric,
        fontWeight: AppFontWeight.bold,
        letterSpacing: AppLetterSpacing.ritual,
      ),
    );
  }

  // ────────────────────────── Helpers ──────────────────────────────

  /// Draws [text] centered at [pos]. Always disposes the [TextPainter] to
  /// prevent native handle leaks (project hard rule).
  void _drawText(Canvas canvas, String text, Offset pos, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    // Compensate for trailing letterSpacing so the text is truly centered.
    final adjust = (style.letterSpacing ?? 0) / 2;
    tp.paint(canvas, pos - Offset(tp.width / 2 - adjust, tp.height / 2));
    tp.dispose();
  }
}
