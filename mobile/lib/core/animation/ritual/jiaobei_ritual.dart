// Copyright (c) 2026 Qore
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';
import 'ritual_animation.dart';

/// Jiaobei (杯筊) ritual entrance animation: two crescent blocks are thrown
/// from the top corners, tumble through the air, land with a small bounce
/// and settle into one of three results — 圣筊 / 笑筊 / 阴筊.
///
/// Total duration ~3s ([AppAnimations.ritualJiaobei]). Progress 0.0 → 1.0:
///  - Phase 1 (0.00-0.15): dark background fades in.
///  - Phase 2 (0.15-0.60): two crescent blocks thrown from the top corners,
///    parabolic fall with ~2 full tumbling rotations each.
///  - Phase 3 (0.60-0.85): blocks land at the bottom with a small bounce
///    and squash, then settle into their final orientation.
///  - Phase 4 (0.85-1.00): result solidifies — a colored glow appears
///    (gold for 圣筊, soft gold for 笑筊, dim blue for 阴筊) and the result
///    label fades in.
class JiaobeiRitual extends RitualAnimation {
  const JiaobeiRitual({super.key, super.onCompleted});

  @override
  RitualAnimationState<JiaobeiRitual> createState() =>
      _JiaobeiRitualState();
}

class _JiaobeiRitualState extends RitualAnimationState<JiaobeiRitual> {
  late final AnimationController _ctrl;
  late final _RitualParams _p;

  @override
  void initState() {
    super.initState();
    _p = _RitualParams.random();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.ritualJiaobei),
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

/// Pre-generated random parameters for one ritual run.
class _RitualParams {
  /// Two pieces. `true` = yang face (flat, 阳) up; `false` = yin face (convex, 阴) up.
  final List<bool> pieces;

  /// Per-piece tumbling rotation seed for variety.
  final List<double> rotations;

  _RitualParams(this.pieces, this.rotations);

  factory _RitualParams.random() {
    final rng = math.Random();
    return _RitualParams(
      [rng.nextBool(), rng.nextBool()],
      [rng.nextDouble() * math.pi, rng.nextDouble() * math.pi],
    );
  }

  /// Result label based on the two pieces.
  String get resultLabel {
    if (pieces[0] != pieces[1]) return '圣筊';
    return pieces[0] ? '笑筊' : '阴筊';
  }
}

class _RitualPainter extends CustomPainter {
  final double t; // overall progress 0..1
  final _RitualParams p;

  _RitualPainter(this.t, this.p);

  @override
  bool shouldRepaint(covariant _RitualPainter old) => true;

  /// Sub-interval progress within [a, b], clamped to 0..1.
  double _iv(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  /// easeIn (accelerating) for falling.
  double _easeIn(double x) => x * x;

  /// easeOut (decelerating) for landing / glow.
  double _easeOut(double x) => 1 - math.pow(1 - x, 3).toDouble();

  // —— Layout constants ——
  static const double _pieceW = 96.0;
  static const double _pieceH = 30.0;
  static const double _pieceGap = 76.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final landY = size.height * 0.62;
    final startY = -_pieceH * 2;

    // Phase 1: background fade in.
    _drawBackground(canvas, size);

    // Faint "掷筊" watermark.
    _drawWatermark(canvas, size, _iv(0.0, 0.5));

    // Phases 2-4: draw each crescent piece.
    for (var i = 0; i < 2; i++) {
      _drawPiece(canvas, i, cx, size.width, startY, landY);
    }

    // Phase 4: result glow + label.
    final settleT = _iv(0.85, 1.0);
    if (settleT > 0) {
      _drawResultGlow(canvas, cx, landY, settleT);
      _drawResultLabel(canvas, cx, landY + 100, settleT);
    }
  }

  // ---- Phase 1: Background ----

  void _drawBackground(Canvas canvas, Size size) {
    final bgA = _iv(0.0, 0.15);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.bg.withValues(alpha: bgA),
    );
  }

  /// Draw a faint "掷筊" watermark in the background.
  void _drawWatermark(Canvas canvas, Size size, double progress) {
    if (progress <= 0) return;
    _drawText(
      canvas,
      '掷筊',
      Offset(size.width / 2, size.height / 2),
      TextStyle(
        color: AppColors.gold.withValues(alpha: progress * 0.06),
        fontSize: size.shortestSide * 0.28,
        fontWeight: AppFontWeight.bold,
        letterSpacing: AppLetterSpacing.ritualDisplayWide,
      ),
    );
  }

  // ---- Phases 2-4: Crescent pieces ----

  void _drawPiece(
    Canvas canvas,
    int i,
    double cx,
    double screenW,
    double startY,
    double landY,
  ) {
    final fallT = _iv(0.15, 0.60);
    final bounceT = _iv(0.60, 0.85);
    final settleT = _iv(0.85, 1.0);

    if (fallT == 0 && bounceT == 0 && settleT == 0) return;

    final side = i == 0 ? -1.0 : 1.0;
    final startX = screenW * 0.5 + side * screenW * 0.35;
    final endX = cx + side * _pieceGap / 2;

    final targetRot = p.pieces[i] ? 0.0 : math.pi;
    // Total rotation during fall: ~2 full turns, landing on target orientation.
    final fallEndRot = targetRot + 4 * math.pi;

    double x, y, rotation;
    double scaleY = 1.0;

    if (fallT > 0 && bounceT == 0) {
      // Phase 2: falling + tumbling (easeIn acceleration).
      final e = _easeIn(fallT);
      x = ui.lerpDouble(startX, endX, e)!;
      y = ui.lerpDouble(startY, landY, e)!;
      rotation = fallEndRot * fallT;
    } else {
      // Phase 3 or 4: at landing position.
      x = endX;
      rotation = targetRot;
      if (bounceT > 0 && bounceT < 1) {
        // Phase 3: bounce — vertical overshoot with slight squash at impact.
        final yOff = math.sin(bounceT * math.pi) * 14;
        y = landY - yOff;
        // Squash only at the very start (impact moment).
        final squash = math.max(0.0, 1 - bounceT * 4);
        scaleY = 1 - 0.18 * squash;
      } else {
        // Phase 4: fully settled.
        y = landY;
        scaleY = 1.0;
      }
    }

    _drawCrescent(canvas, Offset(x, y), rotation, scaleY);
  }

  /// Draw a crescent-shaped cup piece (杯筊).
  ///
  /// The concave side (opening upward at rotation 0) is the yang face (阳);
  /// the convex side is the yin face (阴). The bright golden stroke marks
  /// the yang (inscribed) edge, making the orientation visually clear.
  void _drawCrescent(
    Canvas canvas,
    Offset pos,
    double rotation,
    double scaleY,
  ) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);
    canvas.scale(1, scaleY);

    final w = _pieceW;
    final h = _pieceH;

    // Filled crescent body: outer convex arc + inner concave arc.
    final body = Path()
      ..moveTo(-w / 2, 0)
      ..quadraticBezierTo(0, h, w / 2, 0)
      ..quadraticBezierTo(0, h * 0.4, -w / 2, 0)
      ..close();

    canvas.drawPath(
      body,
      Paint()..color = AppColors.earth.withValues(alpha: 0.92),
    );

    // Convex edge (yin face) — subtle stroke.
    final convex = Path()
      ..moveTo(-w / 2, 0)
      ..quadraticBezierTo(0, h, w / 2, 0);
    canvas.drawPath(
      convex,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.gold.withValues(alpha: 0.35)
        ..strokeWidth = 1.0,
    );

    // Concave edge (yang face) — bright golden stroke.
    final concave = Path()
      ..moveTo(-w / 2, 0)
      ..quadraticBezierTo(0, h * 0.4, w / 2, 0);
    canvas.drawPath(
      concave,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.goldBright.withValues(alpha: 0.85)
        ..strokeWidth = 1.6,
    );

    canvas.restore();
  }

  // ---- Phase 4: Result glow + label ----

  /// Draw a colored glow around both landed pieces based on the result type.
  void _drawResultGlow(
    Canvas canvas,
    double cx,
    double landY,
    double settleT,
  ) {
    final e = _easeOut(settleT);
    final glowColor = _resultGlowColor();
    final glowR = _pieceGap + 50.0;
    final cy = landY - 5;

    canvas.drawCircle(
      Offset(cx, cy),
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            glowColor.withValues(alpha: e * 0.18),
            glowColor.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: glowR),
        ),
    );
  }

  /// Draw the result label fading in below the pieces.
  void _drawResultLabel(
    Canvas canvas,
    double cx,
    double y,
    double settleT,
  ) {
    final e = _easeOut(settleT);
    _drawText(
      canvas,
      p.resultLabel,
      Offset(cx, y),
      TextStyle(
        color: _resultGlowColor().withValues(alpha: e),
        fontSize: AppFontSize.headingSmall,
        fontWeight: AppFontWeight.bold,
        letterSpacing: AppLetterSpacing.ritual,
      ),
    );
  }

  /// Glow color based on result type:
  /// 圣筊 → goldBright, 笑筊 → goldLight, 阴筊 → yin (cool blue).
  Color _resultGlowColor() {
    if (p.pieces[0] != p.pieces[1]) return AppColors.goldBright;
    return p.pieces[0] ? AppColors.goldLight : AppColors.yin;
  }

  // ---- Text helper (always disposes TextPainter) ----

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
