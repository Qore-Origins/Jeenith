// Copyright (c) 2026 Qore
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';
import 'ritual_animation.dart';

/// Name-test (测名字) ritual entrance animation: a name materialises at the
/// centre, then the five grids (天/人/地/总/外) bloom around it, each
/// coloured by its wuxing element.
///
/// Timeline (~4.5s, progress 0.0 → 1.0):
///  - 0.00-0.10: dark background fades in, centre glow.
///  - 0.10-0.30: 2-3 sample characters appear one by one (the "name").
///  - 0.30-0.45: 天格 (top) blooms — the ancestral grid.
///  - 0.45-0.60: 人格 (centre) blooms — the main grid, highlighted.
///  - 0.60-0.75: 地格 (bottom) blooms — the formative grid.
///  - 0.75-0.85: 总格 (left) + 外格 (right) bloom.
///  - 0.85-1.00: title "测名字" fades in.
class NameTestRitual extends RitualAnimation {
  const NameTestRitual({super.key, super.onCompleted});

  @override
  ConsumerState<NameTestRitual> createState() => _NameTestRitualState();
}

class _NameTestRitualState extends RitualAnimationState<NameTestRitual> {
  late final AnimationController _ctrl;
  late final _RitualParams _p;

  @override
  void initState() {
    super.initState();
    _p = _RitualParams.random();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.ritualNameTest),
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

/// Random parameters generated once per ritual so the name and grids stay
/// stable across repaints.
class _RitualParams {
  /// 2-3 sample characters representing the name under test.
  final List<String> chars;

  /// Five-element labels for each of the five grids, in canonical order:
  /// 天格, 人格, 地格, 总格, 外格.
  final List<String> wuxings;

  _RitualParams(this.chars, this.wuxings);

  factory _RitualParams.random() {
    final rng = math.Random();
    // Common surname/given characters for the ritual preview.
    const pool = [
      '志', '极', '心', '明', '德', '仁', '义', '礼', '智', '信',
      '安', '平', '吉', '祥', '福', '禄', '寿', '喜', '康', '宁',
    ];
    final n = 2 + rng.nextInt(2); // 2 or 3 chars
    final chars = [for (var i = 0; i < n; i++) pool[rng.nextInt(pool.length)]];

    // Random wuxing assignment per grid (5 grids).
    const wxPool = ['金', '木', '水', '火', '土'];
    final wuxings = [
      for (var i = 0; i < 5; i++) wxPool[rng.nextInt(wxPool.length)],
    ];

    return _RitualParams(chars, wuxings);
  }
}

class _RitualPainter extends CustomPainter {
  final double t; // overall progress 0..1
  final _RitualParams p;

  _RitualPainter(this.t, this.p);

  @override
  bool shouldRepaint(covariant _RitualPainter old) => true;

  // Sub-interval progress within [a, b], clamped to 0..1.
  double _iv(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  double _easeOut(double x) => 1 - math.pow(1 - x, 3).toDouble();

  Color _wuxingColor(String wx) => switch (wx) {
        '木' => AppColors.wood,
        '火' => AppColors.fire,
        '土' => AppColors.earth,
        '金' => AppColors.metal,
        '水' => AppColors.waterDeep,
        _ => AppColors.textBody,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final base = math.min(size.width, size.height);

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
        base * 0.28,
        Paint()
          ..shader = RadialGradient(colors: [
            AppColors.gold.withValues(alpha: cgA * 0.30),
            AppColors.gold.withValues(alpha: 0),
          ]).createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: base * 0.28)),
      );
    }

    // —— Phase 1 (0.10-0.30): name characters appear ——
    // Drawn at the vertical centre, slightly above to leave room for the
    // 人格 circle below. Each character fades + scales in sequentially.
    final nameY = cy - base * 0.08;
    final charSize = base * 0.075;
    final charGap = charSize * 1.4;
    final totalW = charSize * p.chars.length +
        charGap * (p.chars.length - 1);
    final startX = cx - totalW / 2 + charSize / 2;
    for (var i = 0; i < p.chars.length; i++) {
      final cp = _iv(0.10 + i * 0.06, 0.10 + i * 0.06 + 0.15);
      if (cp <= 0) continue;
      final e = _easeOut(cp);
      final px = startX + i * (charSize + charGap);
      _drawText(
        canvas,
        p.chars[i],
        Offset(px, nameY),
        TextStyle(
          color: AppColors.goldBright.withValues(alpha: cp),
          fontSize: charSize * e,
          fontWeight: AppFontWeight.bold,
        ),
      );
    }

    // —— Phase 2-5 (0.30-0.85): five grids bloom ——
    // Grid positions (clockwise from top):
    //   天格 = top, 人格 = centre, 地格 = bottom, 总格 = left, 外格 = right
    final gridR = base * 0.20;
    final gridD = base * 0.20;
    final gridRad = base * 0.055;
    final positions = [
      (cx, cy - gridD),         // 0: 天格 (top)
      (cx, cy + gridD * 0.0),   // 1: 人格 (centre)
      (cx, cy + gridD),         // 2: 地格 (bottom)
      (cx - gridR, cy),         // 3: 总格 (left)
      (cx + gridR, cy),         // 4: 外格 (right)
    ];
    final labels = ['天格', '人格', '地格', '总格', '外格'];
    final gridPhases = [
      (0.30, 0.45), // 天格
      (0.45, 0.60), // 人格 (highlighted)
      (0.60, 0.72), // 地格
      (0.72, 0.80), // 总格
      (0.76, 0.84), // 外格 (slight overlap)
    ];

    for (var i = 0; i < 5; i++) {
      final (s, e) = gridPhases[i];
      final gp = _iv(s, e);
      if (gp <= 0) continue;
      final ease = _easeOut(gp);
      final (gx, gy) = positions[i];
      final isRen = i == 1; // 人格 highlighted
      final wx = p.wuxings[i];
      final color = _wuxingColor(wx);
      final r = gridRad * (isRen ? 1.3 : 1.0) * ease;

      // Wuxing-coloured fill (soft).
      canvas.drawCircle(
        Offset(gx, gy),
        r,
        Paint()..color = color.withValues(alpha: gp * 0.18),
      );

      // Border.
      canvas.drawCircle(
        Offset(gx, gy),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = (isRen ? AppColors.goldBright : color)
              .withValues(alpha: gp * 0.85)
          ..strokeWidth = isRen ? 2.0 : 1.4,
      );

      // Wuxing label inside the circle.
      _drawText(
        canvas,
        wx,
        Offset(gx, gy),
        TextStyle(
          color: (isRen ? AppColors.goldBright : color)
              .withValues(alpha: gp),
          fontSize: r * 0.85,
          fontWeight: AppFontWeight.bold,
        ),
      );

      // Grid name label below the circle.
      if (gp > 0.5) {
        _drawText(
          canvas,
          labels[i],
          Offset(gx, gy + r + base * 0.025),
          TextStyle(
            color: (isRen ? AppColors.gold : AppColors.textMeta)
                .withValues(alpha: (gp - 0.5) * 2 * 0.85),
            fontSize: base * 0.022,
            letterSpacing: AppLetterSpacing.label,
          ),
        );
      }

      // Connection line from 人格 (centre) to this grid (skip self).
      if (i != 1 && gp > 0.3) {
        final (rx, ry) = positions[1];
        final lineA = (gp - 0.3) * 0.4;
        canvas.drawLine(
          Offset(rx, ry),
          Offset(gx, gy),
          Paint()
            ..color = AppColors.goldBorder.withValues(alpha: lineA)
            ..strokeWidth = 0.6,
        );
      }
    }

    // —— Phase 6 (0.85-1.00): title fade-in ——
    final titleA = _iv(0.85, 1.0);
    if (titleA > 0) {
      _drawText(
        canvas,
        '测名字',
        Offset(cx, cy + base * 0.30),
        TextStyle(
          color: AppColors.goldBright.withValues(alpha: titleA),
          fontSize: AppFontSize.metric,
          fontWeight: AppFontWeight.bold,
          letterSpacing: AppLetterSpacing.ritual,
        ),
      );
      final subA = _iv(0.92, 1.0);
      if (subA > 0) {
        _drawText(
          canvas,
          '五 格 剖 象',
          Offset(cx, cy + base * 0.37),
          TextStyle(
            color: AppColors.textSubtitle.withValues(alpha: subA * 0.8),
            fontSize: AppFontSize.caption,
            letterSpacing: AppLetterSpacing.display,
          ),
        );
      }
    }
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
