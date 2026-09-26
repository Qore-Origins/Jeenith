// Copyright (c) 2026 Qore
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';
import 'ritual_animation.dart';

/// Cezi (character divination) ritual animation: the glyph "道" emerges from
/// the void, then a five-element color dye radiates from its center outward.
///
/// Timeline (total 5000ms, progress 0.0 -> 1.0):
///  1. 0.00-0.15  Dark background fades in + void particles drift.
///  2. 0.15-0.50  The glyph "道" emerges from screen center (opacity 0->1,
///                 scale 0.7->1.0 with easeOutBack bounce). Whole glyph at once.
///  3. 0.50-0.85  Five-element color (Wood, green) radiates from the glyph
///                 center outward via RadialGradient, dyeing the strokes.
///  4. 0.85-1.00  Glyph fully set + golden outline ring traces around it.
class CeziRitual extends RitualAnimation {
  const CeziRitual({super.key, super.onCompleted});

  @override
  ConsumerState<CeziRitual> createState() => _CeziRitualState();
}

class _CeziRitualState extends RitualAnimationState<CeziRitual> {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.ritualCezi),
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
          painter: _CeziRitualPainter(_ctrl.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// The demo glyph shown during the ritual. "道" echoes the project's
/// pursuit of the Way; the real user input happens on the cezi page.
const String _glyph = '道';

/// Five-element attribute assigned to the demo glyph.
/// Wood (木) — chosen for "道" (the Way): the living, growing path.
/// Full five-element palette for reference:
///   金 Metal #E8D9A0 · 木 Wood #6BAB6B · 水 Water #4A6FA5
///   火 Fire  #E85A3C · 土 Earth #B8893D
const Color _wuxingColor = AppColors.ritualWood;
const String _wuxingName = '木';

class _CeziRitualPainter extends CustomPainter {
  final double t; // overall progress 0..1
  _CeziRitualPainter(this.t);

  @override
  bool shouldRepaint(covariant _CeziRitualPainter old) => true;

  /// Interval-based progress: maps t within [a, b] to 0..1, clamped.
  double _iv(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  /// Cubic ease-out: fast start, slow end.
  double _easeOut(double x) => 1 - math.pow(1 - x, 3).toDouble();

  /// Ease-out-back: overshoots slightly past 1 then settles (landing bounce).
  double _easeOutBack(double x) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return 1 + c3 * math.pow(x - 1, 3) + c1 * math.pow(x - 1, 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final R = math.min(size.width, size.height) * 0.28;

    // Phase 1: background fade in + void particles
    _drawBackground(canvas, size, cx, cy);

    // Phase 2 + 3: glyph emerges then gets dyed (single draw, color shifts)
    _drawGlyph(canvas, cx, cy, R);

    // Phase 3 overlay: dye glow halo
    _drawDyeHalo(canvas, cx, cy, R);

    // Phase 4: golden outline ring + title
    _drawGoldenRing(canvas, cx, cy, R);
  }

  // ---- Phase 1: Background + void particles ----

  void _drawBackground(Canvas canvas, Size size, double cx, double cy) {
    final bgA = _iv(0.0, 0.15);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.bg.withValues(alpha: bgA),
    );

    // Void dust motes drift gently. Deterministic positions via golden ratio.
    final particleT = _iv(0.0, 0.50);
    if (particleT <= 0) return;

    const count = 36;
    const phi = 1.61803398875;
    for (var i = 0; i < count; i++) {
      final angle = i * phi * 2.5;
      final baseDist = 40.0 + (i % 9) * 38.0;
      final drift = math.sin(t * 6.2832 * 1.5 + i * 0.7) * 6.0;
      final dist = baseDist + drift;
      final px = cx + dist * math.cos(angle);
      final py = cy + dist * math.sin(angle);
      final twinkle =
          0.10 + 0.10 * math.sin(t * 6.2832 + i * 0.9);
      final alpha = (twinkle * particleT).clamp(0.0, 0.25);
      canvas.drawCircle(
        Offset(px, py),
        1.0 + (i % 3) * 0.5,
        Paint()..color = AppColors.gold.withValues(alpha: alpha),
      );
    }
  }

  // ---- Phase 2 + 3: Glyph emerges and gets dyed ----

  void _drawGlyph(Canvas canvas, double cx, double cy, double R) {
    final charT = _iv(0.15, 0.50);
    if (charT <= 0) return;

    final e = _easeOutBack(charT.clamp(0.0, 1.0));
    final opacity = charT.clamp(0.0, 1.0);
    final scale = 0.7 + 0.3 * e;
    // Bake scale into font size to keep the dye gradient aligned (no transform).
    final fontSize = R * 1.6 * scale;

    // Dye progress: 0 = pure gold, 1 = fully dyed with element color.
    final dyeT = _iv(0.50, 0.85);

    final Paint textPaint;
    if (dyeT <= 0) {
      // Phase 2: solid gold glyph, no dye yet.
      textPaint = Paint()
        ..color = AppColors.goldBright.withValues(alpha: opacity);
    } else {
      // Phase 3: radial gradient dye spreading from center outward.
      // Inside the dye front -> element color; outside -> original gold.
      final gradientRadius = R * 1.0;
      final frontRadius = gradientRadius * _easeOut(dyeT);
      final frontStop =
          (frontRadius / gradientRadius).clamp(0.001, 0.999);
      textPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          colors: [
            _wuxingColor.withValues(alpha: opacity),
            _wuxingColor.withValues(alpha: opacity),
            AppColors.goldBright.withValues(alpha: opacity),
            AppColors.goldBright.withValues(alpha: opacity),
          ],
          stops: [
            0.0,
            frontStop,
            (frontStop + 0.001).clamp(0.0, 1.0),
            1.0,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(cx, cy),
            radius: gradientRadius,
          ),
        );
    }

    _drawText(
      canvas,
      _glyph,
      Offset(cx, cy),
      TextStyle(
        foreground: textPaint,
        fontSize: fontSize,
        fontWeight: AppFontWeight.bold,
      ),
    );
  }

  // ---- Phase 3 overlay: Dye glow halo ----

  void _drawDyeHalo(Canvas canvas, double cx, double cy, double R) {
    final dyeT = _iv(0.50, 0.85);
    if (dyeT <= 0) return;

    final e = _easeOut(dyeT);
    final haloRadius = R * 1.8 * e;

    // Soft radial halo around the glyph, tinted with the element color.
    canvas.drawCircle(
      Offset(cx, cy),
      haloRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _wuxingColor.withValues(alpha: e * 0.30),
            _wuxingColor.withValues(alpha: e * 0.10),
            _wuxingColor.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: haloRadius),
        ),
    );

    // Element name label appears near the end of the dye phase.
    if (dyeT > 0.65) {
      final labelA = _iv(0.50 + 0.35 * 0.65, 0.85);
      _drawText(
        canvas,
        '五行 · $_wuxingName',
        Offset(cx, cy + R * 1.35),
        TextStyle(
          color: _wuxingColor.withValues(alpha: labelA * 0.85),
          fontSize: R * 0.16,
          fontWeight: AppFontWeight.medium,
          letterSpacing: AppLetterSpacing.decorative,
        ),
      );
    }
  }

  // ---- Phase 4: Golden outline ring + title ----

  void _drawGoldenRing(Canvas canvas, double cx, double cy, double R) {
    final ringT = _iv(0.85, 1.0);
    if (ringT <= 0) return;

    // Outer golden ring traces around the glyph (0° -> 360°).
    final sweepAngle = 2 * math.pi * ringT;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: R * 1.3),
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.gold.withValues(alpha: ringT * 0.9)
        ..strokeWidth = 2.0,
    );

    // Inner faint companion ring.
    final innerA = _iv(0.85 + 0.15 * 0.3, 1.0);
    if (innerA > 0) {
      canvas.drawCircle(
        Offset(cx, cy),
        R * 1.15,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.goldBright.withValues(alpha: innerA * 0.3)
          ..strokeWidth = 0.8,
      );
    }

    // "测字" title fades in at the very end.
    final titleT = _iv(0.92, 1.0);
    if (titleT > 0) {
      _drawText(
        canvas,
        '测字',
        Offset(cx, cy - R * 1.35),
        TextStyle(
          color: AppColors.goldBright.withValues(alpha: titleT),
          fontSize: R * 0.22,
          fontWeight: AppFontWeight.bold,
          letterSpacing: AppLetterSpacing.ritual,
        ),
      );
    }
  }

  // ---- Text helper (always disposes TextPainter) ----

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
