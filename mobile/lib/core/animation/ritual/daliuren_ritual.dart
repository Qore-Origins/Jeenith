// Copyright (c) 2026 Qore
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';
import 'ritual_animation.dart';

/// Da Liu Ren (大六壬) ritual entrance animation: dual-plate convergence.
///
/// Simulates the Earth Plate (地盘) and Heaven Plate (天盘) — two concentric
/// rings rotating in opposite directions and aligning — followed by the Four
/// Lessons (四课) and Three Transmissions (三传) materialising.
///
/// Timeline (total ~5s, progress 0.0 → 1.0):
///  - 0.00-0.10: dark background fades in, centre point glows.
///  - 0.10-0.25: outer ring (Earth Plate) draws as an arc; 12 Earthly Branch
///    markers reveal sequentially; ring rotates clockwise toward ~30°.
///  - 0.25-0.40: inner ring (Heaven Plate) draws; 12 markers offset; ring
///    rotates counter-clockwise; both rings converge.
///  - 0.40-0.55: rotation eases to rest (easeOut); golden alignment line
///    (日辰) draws between an outer and an inner position.
///  - 0.55-0.75: Four Lessons fade in at the cardinal directions (staggered).
///  - 0.75-0.90: Three Transmissions descend from the top and stack on the
///    left, each leaving a fading light trail.
///  - 0.90-1.00: the diagram glows and the title "大六壬" fades in.
class DaliurenRitual extends RitualAnimation {
  const DaliurenRitual({super.key, super.onCompleted});

  @override
  ConsumerState<DaliurenRitual> createState() => _DaliurenRitualState();
}

class _DaliurenRitualState extends RitualAnimationState<DaliurenRitual> {
  late final AnimationController _ctrl;
  late final _RitualParams _p;

  @override
  void initState() {
    super.initState();
    _p = _RitualParams.random();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.ritualDaliuren),
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
          painter: _RitualPainter(_ctrl.value, _p),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Random parameters generated once per ritual so labels and alignment stay
/// stable across repaints.
class _RitualParams {
  /// Four Lessons labels (Heavenly Stem + Earthly Branch pairs).
  final List<String> lessons;

  /// Three Transmissions labels (name + Stem-Branch pair).
  final List<String> transmissions;

  /// Outer ring alignment marker index (0..11) for the 日辰 line.
  final int outerAlignIdx;

  /// Inner ring alignment marker index (0..11) for the 日辰 line.
  final int innerAlignIdx;

  /// Inner ring angular offset (radians) representing the Heaven Plate turn.
  final double innerOffset;

  _RitualParams(this.lessons, this.transmissions, this.outerAlignIdx,
      this.innerAlignIdx, this.innerOffset);

  factory _RitualParams.random() {
    final rng = math.Random();
    const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    const branches = [
      '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
    ];
    String randPair() =>
        '${stems[rng.nextInt(stems.length)]}${branches[rng.nextInt(branches.length)]}';

    final lessons = [for (var i = 0; i < 4; i++) randPair()];
    const transNames = ['初传', '中传', '末传'];
    final transmissions = [for (final n in transNames) '$n ${randPair()}'];

    return _RitualParams(
      lessons,
      transmissions,
      rng.nextInt(12),
      rng.nextInt(12),
      // Heaven Plate turned 1-3 positions (30°-90°) relative to Earth Plate.
      (1 + rng.nextInt(3)) * (math.pi / 6),
    );
  }
}

class _RitualPainter extends CustomPainter {
  final double t; // overall progress 0..1
  final _RitualParams p;

  _RitualPainter(this.t, this.p);

  // The 12 Earthly Branches, placed clockwise starting from the top.
  static const _branches = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
  ];

  @override
  bool shouldRepaint(covariant _RitualPainter old) => true;

  // Sub-interval progress within [a, b], clamped to 0..1.
  double _iv(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  double _easeOut(double x) => 1 - math.pow(1 - x, 3).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final base = math.min(size.width, size.height);
    final outerR = base * 0.34;
    final innerR = base * 0.24;

    // —— Phase 0 (0.00-0.10): background + centre glow ——
    final bgA = _iv(0.0, 0.10);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.bg.withValues(alpha: bgA),
    );
    final cgA = _iv(0.0, 0.10);
    if (cgA > 0) {
      canvas.drawCircle(
        Offset(cx, cy),
        outerR * 0.55,
        Paint()
          ..shader = RadialGradient(colors: [
            AppColors.gold.withValues(alpha: cgA * 0.32),
            AppColors.gold.withValues(alpha: 0),
          ]).createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: outerR * 0.55)),
      );
    }

    // —— Rotations: converge (easeOut) to rest by 0.55 ——
    // Outer rotates clockwise (positive) to +30° over [0.10, 0.55].
    final outerRot = _easeOut(_iv(0.10, 0.55)) * (math.pi / 6);
    // Inner rotates counter-clockwise (negative) to -30° over [0.25, 0.55].
    final innerRot = -_easeOut(_iv(0.25, 0.55)) * (math.pi / 6);

    // —— Phase 1 (0.10-0.25): outer ring (Earth Plate) ——
    final outerArc = _iv(0.10, 0.25);
    if (outerArc > 0) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(outerRot);
      _drawRing(canvas, outerR, outerArc, AppColors.gold, 2, 16, 12);
      canvas.restore();
    }

    // —— Phase 2 (0.25-0.40): inner ring (Heaven Plate, offset) ——
    final innerArc = _iv(0.25, 0.40);
    if (innerArc > 0) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(innerRot + p.innerOffset);
      _drawRing(canvas, innerR, innerArc, AppColors.goldBright, 2, 13, 10);
      canvas.restore();
    }

    // —— Phase 3 (0.40-0.55): alignment line (日辰) ——
    final lineP = _iv(0.40, 0.55);
    if (lineP > 0) {
      final oAng = -math.pi / 2 + p.outerAlignIdx * (math.pi / 6) + outerRot;
      final iAng =
          -math.pi / 2 + p.innerAlignIdx * (math.pi / 6) + innerRot + p.innerOffset;
      final ox = cx + outerR * math.cos(oAng);
      final oy = cy + outerR * math.sin(oAng);
      final ix = cx + innerR * math.cos(iAng);
      final iy = cy + innerR * math.sin(iAng);
      final e = _easeOut(lineP);
      final lx = ox + (ix - ox) * e;
      final ly = oy + (iy - oy) * e;
      canvas.drawCircle(
        Offset(ox, oy),
        3,
        Paint()..color = AppColors.goldLight.withValues(alpha: lineP),
      );
      canvas.drawLine(
        Offset(ox, oy),
        Offset(lx, ly),
        Paint()
          ..color = AppColors.goldLight.withValues(alpha: lineP)
          ..strokeWidth = 1.6,
      );
      // Cap dot at the inner endpoint once the line is fully drawn.
      if (lineP >= 1) {
        canvas.drawCircle(
          Offset(ix, iy),
          3,
          Paint()..color = AppColors.goldLight,
        );
      }
    }

    // —— Phase 4 (0.55-0.75): Four Lessons (四课), staggered ~100ms ——
    final lessonPhase = _iv(0.55, 0.75);
    if (lessonPhase > 0) {
      final lessonCentres = [
        Offset(cx, cy - outerR - 22), // top
        Offset(cx + outerR + 22, cy), // right
        Offset(cx, cy + outerR + 22), // bottom
        Offset(cx - outerR - 22, cy), // left
      ];
      for (var i = 0; i < 4; i++) {
        // 0.02 of 5000ms = 100ms stagger; fade duration ~0.06 (300ms).
        final lp = _iv(0.55 + i * 0.02, 0.55 + i * 0.02 + 0.06);
        if (lp <= 0) continue;
        _drawPill(canvas, lessonCentres[i], p.lessons[i], lp, 50, 24, 6, 13);
      }
    }

    // —— Phase 5 (0.75-0.90): Three Transmissions (三传) descend ——
    final transPhase = _iv(0.75, 0.90);
    if (transPhase > 0) {
      // Keep the stack on screen while staying just left of the rings.
      final leftX = math.max(34.0, cx - outerR - 30);
      final startY = math.max(24.0, cy - outerR - 60);
      for (var i = 0; i < 3; i++) {
        final tp = _iv(0.75 + i * 0.04, 0.75 + i * 0.04 + 0.10);
        if (tp <= 0) continue;
        final e = _easeOut(tp);
        final finalY = cy + 34 + i * 32;
        final curY = startY + (finalY - startY) * e;
        // Fading light trail along the travelled path while descending.
        if (tp < 1) {
          final trailRect = Rect.fromLTWH(leftX - 1, startY, 2, curY - startY);
          if (trailRect.height > 1) {
            canvas.drawRect(
              trailRect,
              Paint()
                ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gold.withValues(alpha: 0),
                    AppColors.goldBright.withValues(alpha: 0.45 * (1 - tp)),
                  ],
                ).createShader(trailRect),
            );
          }
        }
        _drawPill(
            canvas, Offset(leftX, curY), p.transmissions[i], tp, 62, 28, 14, 10);
      }
    }

    // —— Phase 6 (0.90-1.00): diagram glow + title ——
    final glow = _iv(0.90, 1.00);
    if (glow > 0) {
      canvas.drawCircle(
        Offset(cx, cy),
        outerR * 1.35,
        Paint()
          ..shader = RadialGradient(colors: [
            AppColors.gold.withValues(alpha: glow * 0.12),
            AppColors.gold.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(
              center: Offset(cx, cy), radius: outerR * 1.35)),
      );
    }
    final titleA = _iv(0.92, 1.0);
    if (titleA > 0) {
      _drawText(
        canvas,
        '大六壬',
        Offset(cx, cy + outerR + 58),
        TextStyle(
          color: AppColors.goldBright.withValues(alpha: titleA),
          fontSize: AppFontSize.metric,
          fontWeight: AppFontWeight.bold,
          letterSpacing: AppLetterSpacing.ritual,
        ),
      );
    }
  }

  /// Draws a plate: subtle fill + progressive stroke arc + 12 branch markers.
  ///
  /// Call within an already translated/rotated canvas frame (origin = centre).
  /// Markers reveal sequentially as the sweep passes each 30° position.
  void _drawRing(
    Canvas canvas,
    double r,
    double arcProgress,
    Color stroke,
    double strokeWidth,
    double markerGap,
    double markerFontSize,
  ) {
    // Subtle fill, fading in with the arc.
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = AppColors.gold.withValues(alpha: 0.05 * arcProgress),
    );
    // Progressive stroke (start at top, sweep clockwise) or full circle.
    if (arcProgress >= 1) {
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = stroke
          ..strokeWidth = strokeWidth,
      );
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        -math.pi / 2,
        arcProgress * 2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = stroke
          ..strokeWidth = strokeWidth,
      );
    }
    // 12 Earthly Branch markers, revealed as the sweep passes each position.
    for (var i = 0; i < 12; i++) {
      final ma = (arcProgress * 12 - i).clamp(0.0, 1.0);
      if (ma <= 0) continue;
      final ang = -math.pi / 2 + i * (math.pi / 6);
      final mx = (r + markerGap) * math.cos(ang);
      final my = (r + markerGap) * math.sin(ang);
      _drawText(
        canvas,
        _branches[i],
        Offset(mx, my),
        TextStyle(
          color: AppColors.goldBright.withValues(alpha: ma),
          fontSize: markerFontSize,
        ),
      );
    }
  }

  /// Draws a golden-bordered pill with a centred label, alpha-controlled.
  void _drawPill(
    Canvas canvas,
    Offset center,
    String label,
    double alpha,
    double w,
    double h,
    double radius,
    double fontSize,
  ) {
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(
      rrect,
      Paint()..color = AppColors.panel.withValues(alpha: alpha),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.gold.withValues(alpha: alpha * 0.85)
        ..strokeWidth = 1,
    );
    _drawText(
      canvas,
      label,
      center,
      TextStyle(
        color: AppColors.goldBright.withValues(alpha: alpha),
        fontSize: fontSize,
      ),
    );
  }

  /// Paints centred text and disposes the TextPainter (project hard rule:
  /// CustomPainter implementations must explicitly dispose TextPainter).
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
