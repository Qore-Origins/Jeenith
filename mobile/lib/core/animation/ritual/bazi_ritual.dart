// Copyright (c) 2026 Qore
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';
import 'ritual_animation.dart';

/// Ba-Zi (八字推演) ritual entrance animation: four pillars descend from
/// heaven, each carrying a Heavenly Stem above and an Earthly Branch below.
/// The day pillar (日柱) is the self and is highlighted in gold.
///
/// Timeline (~4.5s, progress 0.0 → 1.0):
///  - 0.00-0.10: dark background fades in, centre glow grows.
///  - 0.10-0.25: year pillar (年柱) descends from top, lands at leftmost slot.
///  - 0.25-0.40: month pillar (月柱) descends, lands next to year.
///  - 0.40-0.55: day pillar (日柱) descends — highlighted, larger glow.
///  - 0.55-0.70: hour pillar (时柱) descends — slightly faded (it is optional).
///  - 0.70-0.85: pillars settle, wuxing colours bloom from each branch.
///  - 0.85-1.00: title "八字推演" fades in at the bottom.
class BaziRitual extends RitualAnimation {
  const BaziRitual({super.key, super.onCompleted});

  @override
  ConsumerState<BaziRitual> createState() => _BaziRitualState();
}

class _BaziRitualState extends RitualAnimationState<BaziRitual> {
  late final AnimationController _ctrl;
  late final _RitualParams _p;

  @override
  void initState() {
    super.initState();
    _p = _RitualParams.random();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.ritualBazi),
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

/// Random parameters generated once per ritual so the four pillars stay
/// stable across repaints.
class _RitualParams {
  /// Four (stem, branch) pairs, one per pillar.
  final List<(String, String)> pillars;

  _RitualParams(this.pillars);

  factory _RitualParams.random() {
    final rng = math.Random();
    const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    const branches = [
      '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
    ];
    String randStem() => stems[rng.nextInt(stems.length)];
    String randBranch() => branches[rng.nextInt(branches.length)];

    return _RitualParams([
      (randStem(), randBranch()),
      (randStem(), randBranch()),
      (randStem(), randBranch()),
      (randStem(), randBranch()),
    ]);
  }
}

class _RitualPainter extends CustomPainter {
  final double t; // overall progress 0..1
  final _RitualParams p;

  _RitualPainter(this.t, this.p);

  // 五行配色 (used for the bloom at the end).
  static const _branchWuxing = {
    '寅': '木', '卯': '木',
    '巳': '火', '午': '火',
    '辰': '土', '戌': '土', '丑': '土', '未': '土',
    '申': '金', '酉': '金',
    '子': '水', '亥': '水',
  };

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
        base * 0.30,
        Paint()
          ..shader = RadialGradient(colors: [
            AppColors.gold.withValues(alpha: cgA * 0.30),
            AppColors.gold.withValues(alpha: 0),
          ]).createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: base * 0.30)),
      );
    }

    // —— Phase 1-4: four pillars descend in sequence ——
    // Pillar layout: 4 columns evenly spaced, centred horizontally.
    final pillarW = base * 0.13;
    final gap = pillarW * 0.55;
    final totalW = pillarW * 4 + gap * 3;
    final startX = cx - totalW / 2 + pillarW / 2;
    // Pillars land at vertical centre, slightly above to leave room for title.
    final landY = cy - base * 0.02;
    // Start above the screen.
    final startY = -base * 0.20;

    final pillarPhases = [
      (0.10, 0.25), // 年柱
      (0.25, 0.40), // 月柱
      (0.40, 0.55), // 日柱 (highlighted)
      (0.55, 0.70), // 时柱 (faded, optional)
    ];
    final pillarLabels = ['年柱', '月柱', '日柱', '时柱'];

    for (var i = 0; i < 4; i++) {
      final (s, e) = pillarPhases[i];
      final p1 = _iv(s, e);
      if (p1 <= 0) continue;
      final ease = _easeOut(p1);
      final px = startX + i * (pillarW + gap);
      final py = startY + (landY - startY) * ease;
      final isDay = i == 2; // 日柱 highlighted
      final isHour = i == 3; // 时柱 faded (optional)
      _drawPillar(canvas, px, py, pillarW, p.pillars[i], pillarLabels[i],
          isDay: isDay, isHour: isHour, alpha: p1);
    }

    // —— Phase 5 (0.70-0.85): wuxing bloom ——
    final bloom = _iv(0.70, 0.85);
    if (bloom > 0) {
      for (var i = 0; i < 4; i++) {
        final px = startX + i * (pillarW + gap);
        final (stem, branch) = p.pillars[i];
        final wx = _branchWuxing[branch] ?? '土';
        final color = _wuxingColor(wx);
        canvas.drawCircle(
          Offset(px, landY + pillarW * 0.55),
          pillarW * 0.5 * bloom,
          Paint()
            ..shader = RadialGradient(colors: [
              color.withValues(alpha: bloom * 0.35),
              color.withValues(alpha: 0),
            ]).createShader(Rect.fromCircle(
                center: Offset(px, landY + pillarW * 0.55),
                radius: pillarW * 0.5)),
        );
      }
    }

    // —— Phase 6 (0.85-1.00): title fade-in ——
    final titleA = _iv(0.85, 1.0);
    if (titleA > 0) {
      _drawText(
        canvas,
        '八字推演',
        Offset(cx, cy + base * 0.20),
        TextStyle(
          color: AppColors.goldBright.withValues(alpha: titleA),
          fontSize: AppFontSize.metric,
          fontWeight: AppFontWeight.bold,
          letterSpacing: AppLetterSpacing.ritual,
        ),
      );
      // Subtitle.
      final subA = _iv(0.92, 1.0);
      if (subA > 0) {
        _drawText(
          canvas,
          '四 柱 命 理',
          Offset(cx, cy + base * 0.27),
          TextStyle(
            color: AppColors.textSubtitle.withValues(alpha: subA * 0.8),
            fontSize: AppFontSize.caption,
            letterSpacing: AppLetterSpacing.display,
          ),
        );
      }
    }
  }

  /// Draws a single pillar: a rounded panel with the stem above the branch,
  /// plus a small label below. The day pillar gets a golden border + glow.
  void _drawPillar(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    (String, String) pillar,
    String label, {
    required bool isDay,
    required bool isHour,
    required double alpha,
  }) {
    final (stem, branch) = pillar;
    final h = w * 1.4;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.12));

    // Background fill.
    final fillAlpha = isHour ? alpha * 0.55 : alpha;
    canvas.drawRRect(
      rrect,
      Paint()..color = AppColors.panel.withValues(alpha: fillAlpha * 0.85),
    );

    // Border.
    final borderColor = isDay
        ? AppColors.gold.withValues(alpha: alpha)
        : AppColors.goldBorder.withValues(alpha: alpha * 0.7);
    final strokeWidth = isDay ? 2.0 : 1.2;
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = borderColor
        ..strokeWidth = strokeWidth,
    );

    // Day pillar glow.
    if (isDay && alpha > 0.3) {
      canvas.drawRRect(
        rrect.inflate(4),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.gold.withValues(alpha: alpha * 0.25)
          ..strokeWidth = 6,
      );
    }

    // Stem (upper).
    _drawText(
      canvas,
      stem,
      Offset(cx, cy - h * 0.18),
      TextStyle(
        color: (isDay ? AppColors.goldBright : AppColors.textPrimary)
            .withValues(alpha: alpha),
        fontSize: w * 0.42,
        fontWeight: AppFontWeight.bold,
      ),
    );

    // Divider.
    final divY = cy + h * 0.02;
    canvas.drawLine(
      Offset(cx - w * 0.30, divY),
      Offset(cx + w * 0.30, divY),
      Paint()
        ..color = AppColors.goldBorder.withValues(alpha: alpha * 0.5)
        ..strokeWidth = 0.8,
    );

    // Branch (lower).
    _drawText(
      canvas,
      branch,
      Offset(cx, cy + h * 0.22),
      TextStyle(
        color: (isDay ? AppColors.goldBright : AppColors.textPrimary)
            .withValues(alpha: alpha),
        fontSize: w * 0.42,
        fontWeight: AppFontWeight.bold,
      ),
    );

    // Label below the pillar.
    if (alpha > 0.5) {
      _drawText(
        canvas,
        label,
        Offset(cx, cy + h * 0.65),
        TextStyle(
          color: (isDay ? AppColors.gold : AppColors.textMeta)
              .withValues(alpha: (alpha - 0.5) * 2 * 0.85),
          fontSize: w * 0.18,
          letterSpacing: AppLetterSpacing.label,
        ),
      );
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
