// Copyright (c) 2026 Qore
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';
import 'ritual_animation.dart';

/// Sample invocation poem shown on the unfolding scroll. This is NOT the
/// divination result — the actual stick is drawn later on the tech page.
const List<String> _invocationPoem = [
  '诚心叩天地',
  '静意问神明',
  '签开玄机显',
  '福祸原本心',
];

/// Chouqian (抽签) ritual animation: bamboo tube shakes, a stick leaps out,
/// unfolds into a scroll, and the invocation poem is brush-written line by
/// line. Total duration 5 s ([AppAnimations.ritualChouqian]).
///
/// Timeline (progress 0.0 → 1.0):
///  1. **0.00–0.20** — Dark background fades in. The bamboo stick tube
///     appears at center and sways ±15° (sin wave, decaying).
///  2. **0.20–0.48** — One stick leaps out of the tube (arc trajectory up
///     then down, with slight rotation + scale). The tube fades out.
///  3. **0.42–0.60** — The stick lands at center and unfolds into a scroll:
///     paper width grows 0 → target, the two rollers separate.
///  4. **0.60–0.90** — The invocation poem is brush-written on the scroll,
///     line by line top to bottom (staggered left-to-right reveal per line).
///  5. **0.90–1.00** — Golden border traces the scroll edges; title "灵签"
///     fades in with a soft golden glow.
class ChouqianRitual extends RitualAnimation {
  const ChouqianRitual({super.key, super.onCompleted});

  @override
  RitualAnimationState<ChouqianRitual> createState() =>
      _ChouqianRitualState();
}

class _ChouqianRitualState extends RitualAnimationState<ChouqianRitual> {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.ritualChouqian),
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
          painter: _ChouqianRitualPainter(_ctrl.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Painter for the Chouqian ritual. Draws all five phases onto the canvas
/// based on the global progress [t] (0.0–1.0).
class _ChouqianRitualPainter extends CustomPainter {
  final double t;
  _ChouqianRitualPainter(this.t);

  // ── Layout constants (px) ──
  static const double _tubeW = 56.0;
  static const double _tubeH = 170.0;
  static const double _stickW = 10.0;
  static const double _stickH = 150.0;
  static const double _scrollPaperH = 150.0;
  static const double _scrollMaxW = 230.0;
  static const double _rollerRadius = 16.0;
  static const double _poemFontSize = 17.0;

  // Scroll paper warm beige (not pure white, to avoid glare).
  static const Color _paperColor = AppColors.ritualPaper;
  static const Color _inkColor = AppColors.ritualInk;
  static const Color _stickBodyColor = AppColors.ritualStick;
  static const Color _stickTipColor = AppColors.ritualStickTip;
  static const Color _paperBorder = AppColors.ritualPaperBorder;
  static const Color _rollerCore = AppColors.ritualRoller;
  static const Color _tubeBody = AppColors.ritualTube;
  static const Color _tubeInner = AppColors.ritualTubeInner;

  @override
  bool shouldRepaint(covariant _ChouqianRitualPainter old) => true;

  /// Sub-interval progress within [a, b], clamped to 0..1.
  double _iv(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  /// easeOut (decelerating): 1 - (1 - x)^3.
  double _easeOut(double x) => 1 - math.pow(1 - x, 3).toDouble();

  /// easeInOut: smooth start and end.
  double _easeInOut(double x) =>
      x < 0.5 ? 2 * x * x : 1 - math.pow(-2 * x + 2, 2) / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Phase 1: background fade in (stays for the whole animation).
    _drawBackground(canvas, size);

    // Phases 1–2: bamboo tube (sway then fade out as the stick leaps).
    _drawTube(canvas, cx, cy);

    // Phase 2: stick leaps out of the tube and lands at center.
    _drawLeapingStick(canvas, cx, cy);

    // Phase 3: scroll unfolds at center.
    _drawScroll(canvas, cx, cy);

    // Phase 4: brush-written invocation poem on the scroll.
    _drawPoem(canvas, cx, cy);

    // Phase 5: golden border trace + title "灵签".
    _drawBorderAndTitle(canvas, cx, cy);
  }

  // ───────────────────── Phase 1: Background ─────────────────────

  void _drawBackground(Canvas canvas, Size size) {
    final bgA = _iv(0.0, 0.10);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.bg.withValues(alpha: bgA),
    );
  }

  // ───────────────── Phases 1–2: Bamboo Tube ────────────────────

  void _drawTube(Canvas canvas, double cx, double cy) {
    // Appear 0.05–0.15, fade out 0.32–0.40 as the stick leaves.
    final appearT = _iv(0.05, 0.15);
    final fadeT = _iv(0.32, 0.40);
    final alpha = appearT * (1 - fadeT);
    if (alpha <= 0) return;

    // Sway ±15° (sin wave), envelope builds in phase 1 and dies out as the
    // stick leaps.
    final swayEnvelope = (1 - _iv(0.20, 0.35)) * _iv(0.05, 0.20);
    final sway = math.sin(t * 60) * 15 * math.pi / 180 * swayEnvelope;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(sway);

    // Tube body (dark) with rounded corners.
    final bodyRect = Rect.fromCenter(
      center: Offset.zero,
      width: _tubeW,
      height: _tubeH,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(AppRadius.control)),
      Paint()..color = _tubeBody.withValues(alpha: alpha),
    );
    // Inner shading.
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect.deflate(4), const Radius.circular(AppRadius.compactLoose)),
      Paint()..color = _tubeInner.withValues(alpha: alpha * 0.8),
    );

    // Gold rims (top + bottom).
    final rimPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: alpha)
      ..strokeWidth = 2.5;
    canvas.drawLine(
      Offset(-_tubeW / 2, -_tubeH / 2 + 6),
      Offset(_tubeW / 2, -_tubeH / 2 + 6),
      rimPaint,
    );
    canvas.drawLine(
      Offset(-_tubeW / 2, _tubeH / 2 - 6),
      Offset(_tubeW / 2, _tubeH / 2 - 6),
      rimPaint,
    );

    // A few stick tops peeking from the tube mouth (decorative).
    for (final dx in [-14.0, 0.0, 14.0]) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(dx, -_tubeH / 2 + 2), width: 4, height: 14),
        Paint()..color = _stickBodyColor.withValues(alpha: alpha * 0.9),
      );
    }

    canvas.restore();
  }

  // ──────────────────── Phase 2: Leaping Stick ───────────────────

  void _drawLeapingStick(Canvas canvas, double cx, double cy) {
    final stickProgress = _iv(0.20, 0.48);
    if (stickProgress <= 0) return;

    // Fade in 0.20–0.25, fade out 0.42–0.48 as the scroll takes over.
    final alpha = _iv(0.20, 0.25) * (1 - _iv(0.42, 0.48));
    if (alpha <= 0) return;

    // Arc trajectory: tube mouth → peak → center (lands where scroll opens).
    final startY = cy - _tubeH / 2;
    final peakY = startY - 130;
    final endY = cy;
    final double sy;
    if (stickProgress < 0.5) {
      sy = ui.lerpDouble(startY, peakY, stickProgress * 2)!;
    } else {
      sy = ui.lerpDouble(peakY, endY, (stickProgress - 0.5) * 2)!;
    }

    // Slight horizontal drift mirroring the sway.
    final sx = cx + math.sin(stickProgress * math.pi) * 6;
    // Rotation: tilt out then settle back.
    final rot = math.sin(stickProgress * math.pi) * 0.45;
    // Scale: grow on exit, shrink as it morphs into the scroll.
    final scale = stickProgress < 0.5
        ? ui.lerpDouble(0.7, 1.0, stickProgress * 2)!
        : ui.lerpDouble(1.0, 0.85, (stickProgress - 0.5) * 2)!;

    canvas.save();
    canvas.translate(sx, sy);
    canvas.rotate(rot);
    canvas.scale(scale);

    // Stick body (bamboo).
    final bodyRect = Rect.fromCenter(
      center: Offset.zero,
      width: _stickW,
      height: _stickH,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(AppRadius.compact)),
      Paint()..color = _stickBodyColor.withValues(alpha: alpha),
    );
    // Red tip (top of the stick).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -_stickH / 2 + 6),
          width: _stickW,
          height: 14,
        ),
        const Radius.circular(AppRadius.tiny),
      ),
      Paint()..color = _stickTipColor.withValues(alpha: alpha),
    );
    // Gold accent line down the body.
    canvas.drawLine(
      Offset(0, -_stickH / 2 + 18),
      Offset(0, _stickH / 2 - 4),
      Paint()
        ..color = AppColors.goldBright.withValues(alpha: alpha * 0.6)
        ..strokeWidth = 1,
    );

    canvas.restore();
  }

  // ──────────────────── Phase 3: Unfolding Scroll ────────────────

  void _drawScroll(Canvas canvas, double cx, double cy) {
    final unfoldT = _iv(0.42, 0.60);
    if (unfoldT <= 0) return;

    final e = _easeInOut(unfoldT);
    final paperW = _scrollMaxW * e;
    if (paperW < 1) return;

    final paperRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: paperW,
      height: _scrollPaperH,
    );

    // Paper face (warm beige, not pure white to avoid glare).
    canvas.drawRect(paperRect, Paint()..color = _paperColor);

    // Subtle inner border on the paper.
    canvas.drawRect(
      paperRect.deflate(6),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _paperBorder.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // Left and right rollers (circular axes) that separate as the scroll
    // opens. When paperW is tiny both rollers sit together like a rolled
    // scroll.
    for (final dx in [-paperW / 2, paperW / 2]) {
      final center = Offset(cx + dx, cy);
      // Darker core.
      canvas.drawCircle(
        center,
        _rollerRadius,
        Paint()..color = _rollerCore,
      );
      // Gold rim.
      canvas.drawCircle(
        center,
        _rollerRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.goldBright
          ..strokeWidth = 2.5,
      );
      // End-cap highlight.
      canvas.drawCircle(
        center,
        _rollerRadius * 0.4,
        Paint()..color = AppColors.gold,
      );
    }
  }

  // ──────────────── Phase 4: Brush-written Poem ──────────────────

  void _drawPoem(Canvas canvas, double cx, double cy) {
    final poemT = _iv(0.60, 0.90);
    if (poemT <= 0) return;

    const lineCount = 4;
    const lineStagger = 0.06; // each line starts 0.06 later
    const lineDur = 0.12;

    final lineH = _poemFontSize + 14;
    final totalH = lineH * lineCount;
    final topY = cy - totalH / 2 + _poemFontSize / 2;

    for (var i = 0; i < lineCount; i++) {
      final lineStart = 0.60 + i * lineStagger;
      final lineT = _iv(lineStart, lineStart + lineDur);
      if (lineT <= 0) continue;

      final text = _invocationPoem[i];
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: _inkColor,
            fontSize: _poemFontSize,
            fontWeight: AppFontWeight.medium,
            letterSpacing: AppLetterSpacing.label,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final lineY = topY + i * lineH;
      final lineX = cx - tp.width / 2;

      // Left-to-right reveal (brush writing effect) via clip rect. The
      // growing clip edge mimics a brush tip sweeping across the paper.
      final revealW = tp.width * lineT;
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(
        lineX,
        lineY - tp.height / 2,
        revealW,
        tp.height,
      ));
      tp.paint(canvas, Offset(lineX, lineY - tp.height / 2));
      canvas.restore();

      tp.dispose();
    }
  }

  // ──────────── Phase 5: Golden Border + Title "灵签" ────────────

  void _drawBorderAndTitle(Canvas canvas, double cx, double cy) {
    final borderT = _iv(0.90, 1.00);
    if (borderT <= 0) return;

    final e = _easeOut(borderT);
    final halfW = _scrollMaxW / 2;
    final halfH = _scrollPaperH / 2;

    // Golden border tracing the scroll's top + bottom edges, growing from
    // the center outward.
    final edgeLen = halfW * e;
    final borderPaint = Paint()
      ..color = AppColors.goldBright
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(cx - edgeLen, cy - halfH),
      Offset(cx + edgeLen, cy - halfH),
      borderPaint,
    );
    canvas.drawLine(
      Offset(cx - edgeLen, cy + halfH),
      Offset(cx + edgeLen, cy + halfH),
      borderPaint,
    );

    // Soft golden glow behind the scroll.
    final glowR = _scrollMaxW * 0.75;
    canvas.drawCircle(
      Offset(cx, cy),
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: e * 0.10),
            AppColors.gold.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowR)),
    );

    // Title "灵签" fades in below the scroll.
    final titleT = _iv(0.92, 1.00);
    if (titleT > 0) {
      _drawText(
        canvas,
        '灵签',
        Offset(cx, cy + halfH + 36),
        TextStyle(
          color: AppColors.goldBright.withValues(alpha: titleT),
          fontSize: AppFontSize.metric,
          fontWeight: AppFontWeight.bold,
          letterSpacing: AppLetterSpacing.ritual,
        ),
      );
    }
  }

  // ────────────────────────── Helpers ────────────────────────────

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
