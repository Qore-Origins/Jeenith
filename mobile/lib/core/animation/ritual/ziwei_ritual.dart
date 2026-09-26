// Copyright (c) 2026 Qore
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';
import 'ritual_animation.dart';

/// Ziwei Dou Shu ritual animation: the golden fate chart unfolds.
///
/// Timeline (total 6000ms, progress 0.0 -> 1.0):
///  1. 0.00-0.10  Dark background fades in.
///  2. 0.10-0.20  Center golden light burst — radial glow + particle burst.
///  3. 0.20-0.55  12 palace sectors radiate outward, staggered 100ms apart.
///  4. 0.55-0.85+ 14 main stars descend from top to palace positions,
///                 staggered 150ms apart with easeOutBack landing bounce.
///  5. 0.85-1.00  Golden border traces the outer circle; "紫微斗数" fades in.
class ZiweiRitual extends RitualAnimation {
  const ZiweiRitual({super.key, super.onCompleted});

  @override
  ConsumerState<ZiweiRitual> createState() => _ZiweiRitualState();
}

class _ZiweiRitualState extends RitualAnimationState<ZiweiRitual> {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.ritualZiwei),
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
          painter: _ZiweiRitualPainter(_ctrl.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Palace names in traditional Ziwei Dou Shu order.
const List<String> _palaceNames = [
  '命宫', '兄弟', '夫妻', '子女', '财帛', '疾厄',
  '迁移', '奴仆', '官禄', '田宅', '福德', '父母',
];

/// Fourteen main stars of Ziwei Dou Shu.
const List<String> _starNames = [
  '紫微', '天机', '太阳', '武曲', '天同', '廉贞', '天府',
  '太阴', '贪狼', '巨门', '天相', '天梁', '七杀', '破军',
];

class _ZiweiRitualPainter extends CustomPainter {
  final double t; // overall progress 0..1
  _ZiweiRitualPainter(this.t);

  @override
  bool shouldRepaint(covariant _ZiweiRitualPainter old) => true;

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
    final R = math.min(size.width, size.height) * 0.36;

    // Phase 1: background fade in (0.00-0.10)
    _drawBackground(canvas, size);

    // Phase 2: center golden light burst (0.10-0.20)
    _drawLightBurst(canvas, cx, cy, R);

    // Phase 3: 12 palace sectors radiate outward (0.20-0.55)
    _drawPalaceSectors(canvas, cx, cy, R);

    // Phase 4: 14 main stars descend (0.55-0.85+)
    _drawStars(canvas, cx, cy, R);

    // Phase 5: golden border trace + center title (0.85-1.00)
    _drawBorderAndTitle(canvas, cx, cy, R);
  }

  // ---- Phase 1: Background ----

  void _drawBackground(Canvas canvas, Size size) {
    final bgA = _iv(0.0, 0.10);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.bg.withValues(alpha: bgA),
    );
  }

  // ---- Phase 2: Light burst ----

  void _drawLightBurst(Canvas canvas, double cx, double cy, double R) {
    final burstT = _iv(0.10, 0.20);
    if (burstT <= 0) return;

    final e = _easeOut(burstT);
    final burstRadius = R * 0.9 * e;

    // Radial gradient glow expanding from center
    canvas.drawCircle(
      Offset(cx, cy),
      burstRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.goldBright.withValues(alpha: e * 0.50),
            AppColors.gold.withValues(alpha: e * 0.25),
            AppColors.gold.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: burstRadius),
        ),
    );

    // 24 golden particles radiating outward, fading
    const particleCount = 24;
    for (var i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final dist = R * 1.0 * burstT;
      final px = cx + dist * math.cos(angle);
      final py = cy + dist * math.sin(angle);
      final pAlpha = (1 - burstT) * 0.7;
      final pRadius = 2.5 * (1 - burstT * 0.5);
      canvas.drawCircle(
        Offset(px, py),
        pRadius,
        Paint()..color = AppColors.goldBright.withValues(alpha: pAlpha),
      );
    }
  }

  // ---- Phase 3: 12 palace sectors ----

  void _drawPalaceSectors(Canvas canvas, double cx, double cy, double R) {
    const sectorAngle = 2 * math.pi / 12; // 30° per sector
    const stagger = 100 / 6000; // 100ms in progress units (~0.0167)
    const expansionDur = 0.10; // ~600ms per sector expansion

    for (var i = 0; i < 12; i++) {
      final sectorStart = 0.20 + i * stagger;
      final sT = _iv(sectorStart, sectorStart + expansionDur);
      if (sT <= 0) continue;

      final e = _easeOut(sT);
      final radius = R * e;

      // Sector spans from top (-π/2) going clockwise
      final startAngle = -math.pi / 2 + i * sectorAngle;
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

      // Semi-transparent pie-slice fill
      final fillPath = Path()
        ..moveTo(cx, cy)
        ..arcTo(rect, startAngle, sectorAngle, false)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()..color = AppColors.gold.withValues(alpha: 0.06 * sT),
      );

      // Thin golden arc border
      canvas.drawArc(
        rect,
        startAngle,
        sectorAngle,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.gold.withValues(alpha: 0.35 * sT)
          ..strokeWidth = 1.0,
      );

      // Palace name fades in after sector is mostly expanded
      final nameT = _iv(sectorStart + 0.06, sectorStart + 0.12);
      if (nameT > 0 && radius > R * 0.5) {
        final nameAngle = startAngle + sectorAngle / 2;
        final nameRadius = R * 0.78;
        final nx = cx + nameRadius * math.cos(nameAngle);
        final ny = cy + nameRadius * math.sin(nameAngle);
        _drawText(
          canvas,
          _palaceNames[i],
          Offset(nx, ny),
          TextStyle(
            color: AppColors.goldBright.withValues(alpha: nameT * 0.85),
            fontSize: R * 0.075,
            fontWeight: AppFontWeight.medium,
            letterSpacing: AppLetterSpacing.subtle,
          ),
        );
      }
    }
  }

  // ---- Phase 4: 14 main stars descend ----

  void _drawStars(Canvas canvas, double cx, double cy, double R) {
    const stagger = 150 / 6000; // 150ms in progress units (~0.025)
    const descentDur = 0.12; // ~720ms per star descent
    const sectorAngle = 2 * math.pi / 12;

    for (var i = 0; i < 14; i++) {
      final starStart = 0.55 + i * stagger;
      final sT = _iv(starStart, starStart + descentDur);
      if (sT <= 0) continue;

      final e = _easeOutBack(sT.clamp(0.0, 1.0));

      // Target: palace center. Stars 12+ offset inward to avoid overlap.
      final palaceIdx = i % 12;
      final targetAngle =
          -math.pi / 2 + palaceIdx * sectorAngle + sectorAngle / 2;
      final targetRadius = (i >= 12) ? R * 0.55 : R * 0.78;
      final targetX = cx + targetRadius * math.cos(targetAngle);
      final targetY = cy + targetRadius * math.sin(targetAngle);

      // Start: top of screen, spread horizontally
      final startX = cx + (i - 6.5) * 24;
      final startY = -30.0;

      // Current position (with easeOutBack bounce on landing)
      final curX = ui.lerpDouble(startX, targetX, e)!;
      final curY = ui.lerpDouble(startY, targetY, e)!;

      // Light trail: golden gradient line from start to current
      if (sT < 0.95) {
        final trailAlpha = (1 - sT) * 0.4;
        canvas.drawLine(
          Offset(startX, startY),
          Offset(curX, curY),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(startX, startY),
              Offset(curX, curY),
              [
                AppColors.gold.withValues(alpha: 0),
                AppColors.gold.withValues(alpha: trailAlpha),
              ],
            )
            ..strokeWidth = 1.5,
        );
      }

      // Star glow (radial gradient)
      const glowRadius = 14.0;
      canvas.drawCircle(
        Offset(curX, curY),
        glowRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.goldBright.withValues(alpha: sT * 0.50),
              AppColors.gold.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(curX, curY), radius: glowRadius),
          ),
      );

      // Star core
      canvas.drawCircle(
        Offset(curX, curY),
        6.0,
        Paint()..color = AppColors.goldBright.withValues(alpha: sT),
      );

      // Star name label (appears after landing)
      if (sT > 0.6) {
        final labelAlpha =
            _iv(starStart + descentDur * 0.6, starStart + descentDur);
        _drawText(
          canvas,
          _starNames[i],
          Offset(curX, curY - 16),
          TextStyle(
            color: AppColors.goldBright.withValues(alpha: labelAlpha * 0.9),
            fontSize: R * 0.055,
            fontWeight: AppFontWeight.medium,
          ),
        );
      }
    }
  }

  // ---- Phase 5: Border trace + center title ----

  void _drawBorderAndTitle(Canvas canvas, double cx, double cy, double R) {
    // Golden border traces around the outer circle (0° -> 360°)
    final borderT = _iv(0.85, 1.0);
    if (borderT > 0) {
      final sweepAngle = 2 * math.pi * borderT;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: R * 1.05),
        -math.pi / 2,
        sweepAngle,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.gold
          ..strokeWidth = 2.0,
      );
    }

    // Center title "紫微斗数" fades in
    final textT = _iv(0.90, 1.0);
    if (textT > 0) {
      _drawText(
        canvas,
        '紫微斗数',
        Offset(cx, cy),
        TextStyle(
          color: AppColors.goldBright.withValues(alpha: textT),
          fontSize: R * 0.16,
          fontWeight: AppFontWeight.bold,
          letterSpacing: AppLetterSpacing.display,
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
