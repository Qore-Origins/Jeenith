// Copyright (c) 2026 Qore
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';
import 'ritual_animation.dart';

/// Qi Men Dun Jia (奇门遁甲) ritual animation.
///
/// Simulates the nine-palace battle formation assembling itself across six
/// phases (total 5 s, progress 0.0 → 1.0):
///  1. **0.00–0.15** — The 3×3 grid (九宫) is drawn progressively, each cell
///     border growing like a brush stroke.
///  2. **0.15–0.30** — 值符 and 值使 fly into the center cell from opposite
///     corners of the screen, landing with a scale bounce.
///  3. **0.30–0.55** — Eight doors (八门) fly in from the screen edges toward
///     the eight outer cells, staggered 80 ms apart (easeOutCubic).
///  4. **0.55–0.75** — Nine stars (九星) descend from the top into all nine
///     cells, staggered 100 ms apart (easeOutBack landing).
///  5. **0.75–0.90** — Eight gods (八神) fade into the outer corners of each
///     outer cell, staggered.
///  6. **0.90–1.00** — The entire grid glows with a golden border and the
///     title "奇门遁甲" fades in at the top.
class QimenRitual extends RitualAnimation {
  const QimenRitual({super.key, super.onCompleted});

  @override
  QimenRitualState createState() => QimenRitualState();
}

class QimenRitualState extends RitualAnimationState<QimenRitual> {
  late final AnimationController _ctrl;
  late final _QimenParams _params;

  @override
  void initState() {
    super.initState();
    _params = _QimenParams.random();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.ritualQimen),
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
          painter: _QimenPainter(_ctrl.value, _params),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Randomized assignment of doors, stars, and gods to cells for one ritual run.
///
/// Doors and gods are assigned to the 8 outer cells (indices 0–3, 5–8);
/// stars are assigned to all 9 cells (0–8). Each list is shuffled so every
/// run has a different layout.
class _QimenParams {
  final List<int> doorOrder; // 8 outer cell indices, shuffled
  final List<int> starOrder; // 9 cell indices, shuffled
  final List<int> godOrder; // 8 outer cell indices, shuffled

  _QimenParams(this.doorOrder, this.starOrder, this.godOrder);

  factory _QimenParams.random() {
    final rng = math.Random();
    return _QimenParams(
      [0, 1, 2, 3, 5, 6, 7, 8]..shuffle(rng),
      [0, 1, 2, 3, 4, 5, 6, 7, 8]..shuffle(rng),
      [0, 1, 2, 3, 5, 6, 7, 8]..shuffle(rng),
    );
  }
}

/// Painter for the Qi Men Dun Jia ritual. Draws all six phases onto the canvas
/// based on the global progress [t] (0.0–1.0) and the randomized [params].
class _QimenPainter extends CustomPainter {
  final double t;
  final _QimenParams params;

  _QimenPainter(this.t, this.params);

  // Eight doors (八门): Rest, Life, Injury, Du, Scenery, Death, Fear, Open.
  static const List<String> _doors = [
    '休', '生', '伤', '杜', '景', '死', '惊', '开',
  ];

  // Nine stars (九星): Heavenly Peng, Rui, Chong, Fu, Qin, Xin, Zhu, Ren, Ying.
  static const List<String> _stars = [
    '天蓬', '天芮', '天冲', '天辅', '天禽', '天心', '天柱', '天任', '天英',
  ];

  // Eight gods (八神): Chief, Flying Serpent, Great Yin, Six Harmony,
  // Hooked Chen, Vermilion Bird, Nine Earth, Nine Heaven.
  static const List<String> _gods = [
    '直符', '腾蛇', '太阴', '六合', '勾陈', '朱雀', '九地', '九天',
  ];

  /// Gap between adjacent cells (logical pixels).
  static const double _gap = 4.0;

  @override
  bool shouldRepaint(covariant _QimenPainter old) => true;

  /// Sub-interval helper: maps the global progress [t] into a 0–1 range
  /// for the phase spanning [a]–[b].
  double _iv(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  double _easeOutCubic(double x) => 1 - math.pow(1 - x, 3).toDouble();

  double _easeOutBack(double x) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return 1 + c3 * math.pow(x - 1, 3) + c1 * math.pow(x - 1, 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final cellSize = math.min(size.width, size.height) * 0.13;
    final gridW = 3 * cellSize + 2 * _gap;
    final gridH = 3 * cellSize + 2 * _gap;
    final gridLeft = cx - gridW / 2;
    final gridTop = cy - gridH / 2;

    /// Returns the center point of the cell at [index] (0–8, row-major).
    Offset cellCenter(int index) {
      final row = index ~/ 3;
      final col = index % 3;
      return Offset(
        gridLeft + cellSize / 2 + col * (cellSize + _gap),
        gridTop + cellSize / 2 + row * (cellSize + _gap),
      );
    }

    // === Phase 1 (0.00–0.15): Grid draws progressively ===
    final gridT = _iv(0.0, 0.15);
    if (gridT > 0) {
      _drawGrid(canvas, gridLeft, gridTop, cellSize, gridT);
    }

    // === Phase 2 (0.15–0.30): 值符 and 值使 fly into center ===
    final centerT = _iv(0.15, 0.30);
    if (centerT > 0) {
      _drawCenterGenerals(canvas, size, cellCenter(4), cellSize, centerT);
    }

    // === Phase 3 (0.30–0.55): Eight doors fly in from screen edges ===
    // 80 ms stagger ≈ 0.016 of total progress.
    for (var i = 0; i < 8; i++) {
      final start = 0.30 + i * 0.016;
      final doorT = _iv(start, start + 0.15);
      if (doorT <= 0) continue;
      final cellIdx = params.doorOrder[i];
      _drawDoor(canvas, size, cellCenter(cellIdx), cellSize, cellIdx, i, doorT);
    }

    // === Phase 4 (0.55–0.75): Nine stars descend from top ===
    // 100 ms stagger ≈ 0.02 of total progress.
    for (var i = 0; i < 9; i++) {
      final start = 0.55 + i * 0.02;
      final starT = _iv(start, start + 0.12);
      if (starT <= 0) continue;
      final cellIdx = params.starOrder[i];
      _drawStar(canvas, cellCenter(cellIdx), cellSize, i, starT);
    }

    // === Phase 5 (0.75–0.90): Eight gods fade into cell corners ===
    for (var i = 0; i < 8; i++) {
      final start = 0.75 + i * 0.015;
      final godT = _iv(start, start + 0.08);
      if (godT <= 0) continue;
      final cellIdx = params.godOrder[i];
      _drawGod(canvas, cellCenter(cellIdx), cellSize, cellIdx, i, godT);
    }

    // === Phase 6 (0.90–1.00): Grid glow + title ===
    final glowT = _iv(0.90, 1.00);
    if (glowT > 0) {
      _drawGlowAndTitle(
        canvas, size, gridLeft, gridTop, gridW, gridH, cellSize, glowT,
      );
    }
  }

  // ───────────────────────── Phase 1: Grid ─────────────────────────

  /// Draws the 3×3 grid: cell fills fade in, then each cell border grows
  /// progressively like a brush stroke (staggered per cell).
  void _drawGrid(Canvas canvas, double gridLeft, double gridTop,
      double cellSize, double progress) {
    // Cell fills fade in.
    final fillAlpha = (progress * 0.15).clamp(0.0, 0.15);
    final fillPaint = Paint()..color = AppColors.gold.withValues(alpha: fillAlpha);
    for (var i = 0; i < 9; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      canvas.drawRect(
        Rect.fromLTWH(
          gridLeft + col * (cellSize + _gap),
          gridTop + row * (cellSize + _gap),
          cellSize,
          cellSize,
        ),
        fillPaint,
      );
    }

    // Cell borders draw progressively (brush-stroke effect, staggered).
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.gold.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    for (var i = 0; i < 9; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      final cellProgress = ((progress - i * 0.01) / 0.14).clamp(0.0, 1.0);
      if (cellProgress <= 0) continue;
      final rect = Rect.fromLTWH(
        gridLeft + col * (cellSize + _gap),
        gridTop + row * (cellSize + _gap),
        cellSize,
        cellSize,
      );
      // Use PathMetrics to extract a growing portion of the rectangle path.
      final path = Path()..addRect(rect);
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(
          metric.extractPath(0, metric.length * cellProgress),
          borderPaint,
        );
      }
    }
  }

  // ─────────────────────── Phase 2: Generals ───────────────────────

  /// 值符 flies in from the top-left corner, 值使 from the bottom-right.
  /// Both land in the center cell with a scale bounce (easeOutBack).
  void _drawCenterGenerals(Canvas canvas, Size size, Offset center,
      double cellSize, double progress) {
    final e = _easeOutCubic(progress);
    final bounce = _easeOutBack(progress);
    final scale = 0.4 + 0.6 * bounce;
    final alpha = progress.clamp(0.0, 1.0);

    // 值符 targets the left half of the center cell, 值使 the right half.
    final fTarget = center + Offset(-cellSize * 0.22, cellSize * 0.1);
    final sTarget = center + Offset(cellSize * 0.22, cellSize * 0.1);
    final fStart = Offset(-cellSize, -cellSize);
    final sStart = Offset(size.width + cellSize, size.height + cellSize);

    final fPos = Offset(
      ui.lerpDouble(fStart.dx, fTarget.dx, e)!,
      ui.lerpDouble(fStart.dy, fTarget.dy, e)!,
    );
    final sPos = Offset(
      ui.lerpDouble(sStart.dx, sTarget.dx, e)!,
      ui.lerpDouble(sStart.dy, sTarget.dy, e)!,
    );

    _drawText(canvas, '值符', fPos, TextStyle(
      color: AppColors.goldBright.withValues(alpha: alpha),
      fontSize: AppFontSize.body * scale,
      fontWeight: AppFontWeight.bold,
    ));
    _drawText(canvas, '值使', sPos, TextStyle(
      color: AppColors.goldBright.withValues(alpha: alpha),
      fontSize: AppFontSize.body * scale,
      fontWeight: AppFontWeight.bold,
    ));
  }

  // ──────────────────────── Phase 3: Doors ─────────────────────────

  /// A single door character flies in from the screen edge corresponding to
  /// its cell's position, using easeOutCubic.
  void _drawDoor(Canvas canvas, Size size, Offset center, double cellSize,
      int cellIdx, int doorIdx, double progress) {
    final e = _easeOutCubic(progress);
    final alpha = progress.clamp(0.0, 1.0);

    // Determine entry direction based on the cell's position in the grid.
    final row = cellIdx ~/ 3;
    final col = cellIdx % 3;
    Offset start;
    if (row == 0 && col == 0) {
      start = Offset(-cellSize, -cellSize);
    } else if (row == 0 && col == 1) {
      start = Offset(center.dx, -cellSize);
    } else if (row == 0 && col == 2) {
      start = Offset(size.width + cellSize, -cellSize);
    } else if (row == 1 && col == 0) {
      start = Offset(-cellSize, center.dy);
    } else if (row == 1 && col == 2) {
      start = Offset(size.width + cellSize, center.dy);
    } else if (row == 2 && col == 0) {
      start = Offset(-cellSize, size.height + cellSize);
    } else if (row == 2 && col == 1) {
      start = Offset(center.dx, size.height + cellSize);
    } else {
      start = Offset(size.width + cellSize, size.height + cellSize);
    }

    final pos = Offset(
      ui.lerpDouble(start.dx, center.dx, e)!,
      ui.lerpDouble(start.dy, center.dy, e)!,
    );

    _drawText(canvas, _doors[doorIdx], pos, TextStyle(
      color: AppColors.goldBright.withValues(alpha: alpha),
      fontSize: AppFontSize.body,
      fontWeight: AppFontWeight.bold,
    ));
  }

  // ──────────────────────── Phase 4: Stars ─────────────────────────

  /// A star (dot + name label) descends from the top of the screen into its
  /// cell, landing with easeOutBack. The dot has a radial-gradient glow.
  void _drawStar(Canvas canvas, Offset center, double cellSize,
      int starIdx, double progress) {
    final e = _easeOutBack(progress);
    final alpha = progress.clamp(0.0, 1.0);

    final target = center + Offset(0, -cellSize * 0.28);
    final start = Offset(target.dx, -cellSize);
    final pos = Offset(
      ui.lerpDouble(start.dx, target.dx, progress)!,
      ui.lerpDouble(start.dy, target.dy, e)!,
    );

    // Radial-gradient glow halo.
    const dotRadius = 4.0;
    canvas.drawCircle(
      pos,
      dotRadius + 8,
      Paint()
        ..shader = RadialGradient(colors: [
          AppColors.gold.withValues(alpha: alpha * 0.5),
          AppColors.gold.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: pos, radius: dotRadius + 8)),
    );

    // Solid star dot.
    canvas.drawCircle(
      pos,
      dotRadius,
      Paint()..color = AppColors.gold.withValues(alpha: alpha),
    );

    // Star name below the dot.
    _drawText(canvas, _stars[starIdx], pos + const Offset(0, dotRadius + 8),
      TextStyle(
        color: AppColors.textBody.withValues(alpha: alpha),
        fontSize: AppFontSize.micro,
      ),
    );
  }

  // ───────────────────────── Phase 5: Gods ─────────────────────────

  /// A god name fades in at the outer corner of its cell (the corner facing
  /// away from the grid center).
  void _drawGod(Canvas canvas, Offset center, double cellSize,
      int cellIdx, int godIdx, double progress) {
    final alpha = progress.clamp(0.0, 1.0);

    // Choose the corner of the cell that is closest to the screen edge.
    final row = cellIdx ~/ 3;
    final col = cellIdx % 3;
    final dx = col == 0 ? -cellSize * 0.3 : cellSize * 0.3;
    final dy = row == 0 ? -cellSize * 0.3 : cellSize * 0.3;

    final pos = center + Offset(dx, dy);

    _drawText(canvas, _gods[godIdx], pos, TextStyle(
      color: AppColors.textSubtitle.withValues(alpha: alpha * 0.85),
      fontSize: AppFontSize.footnote,
    ));
  }

  // ──────────────────── Phase 6: Glow + Title ──────────────────────

  /// The entire grid border glows golden, and the title "奇门遁甲" fades
  /// in above the grid.
  void _drawGlowAndTitle(Canvas canvas, Size size, double gridLeft,
      double gridTop, double gridW, double gridH, double cellSize,
      double progress) {
    final alpha = progress.clamp(0.0, 1.0);
    final gridRect = Rect.fromLTWH(
      gridLeft - 4, gridTop - 4, gridW + 8, gridH + 8,
    );

    // Soft outer glow.
    canvas.drawRect(
      gridRect.inflate(8),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.gold.withValues(alpha: alpha * 0.15)
        ..strokeWidth = 4,
    );

    // Bright golden border.
    canvas.drawRect(
      gridRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.goldBright.withValues(alpha: alpha * 0.7)
        ..strokeWidth = 1.5,
    );

    // Title "奇门遁甲" centered above the grid.
    final titleY = gridTop - cellSize * 0.9;
    _drawText(canvas, '奇门遁甲', Offset(size.width / 2, titleY), TextStyle(
      color: AppColors.goldBright.withValues(alpha: alpha),
      fontSize: AppFontSize.metric,
      fontWeight: AppFontWeight.bold,
      letterSpacing: AppLetterSpacing.ritual,
    ));
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
