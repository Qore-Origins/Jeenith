// Copyright (c) 2026 Qore
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';
import 'ritual_animation.dart';

/// Meihua Yishu (Plum Blossom Numerology) ritual animation: two numbers
/// drift down from the sky, slam into the upper / lower trigram slots, burst
/// into five-element light, and the hexagram forms with the moving yao
/// descending from above.
///
/// Total duration 4000ms ([AppAnimations.ritualMeihua]). Progress 0.0 → 1.0:
///  - Phase 1 (0.00-0.15): dark bg fades in; two numbers (1..9) drift down
///    from the top corners with a slight rotation (easeIn).
///  - Phase 2 (0.15-0.40): numbers land at 上卦位 (upper) / 下卦位 (lower);
///    impact burst — scale punch 1.0 → 1.25 → 1.0 + golden particle explosion.
///  - Phase 3 (0.40-0.75): numbers dissolve into five-element colored light
///    (金/木/水/火/土 by each trigram's wuxing); upper & lower trigram yao
///    lines fade in.
///  - Phase 4 (0.75-0.95): the moving yao (动爻) descends from the top with a
///    golden beam and gets a golden glow outline.
///  - Phase 5 (0.95-1.00): a golden border traces around the hexagram and
///    "梅花易数" fades in.
class MeihuaRitual extends RitualAnimation {
  const MeihuaRitual({super.key, super.onCompleted});

  @override
  RitualAnimationState<MeihuaRitual> createState() => _MeihuaRitualState();
}

class _MeihuaRitualState extends RitualAnimationState<MeihuaRitual> {
  late final AnimationController _ctrl;
  late final _RitualParams _p;

  @override
  void initState() {
    super.initState();
    _p = _RitualParams.random();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.ritualMeihua),
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
          painter: _MeihuaRitualPainter(_ctrl.value, _p),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Pre-generated random parameters for one ritual run.
///
/// Encodes the full Meihua numerology in advance so the painter stays pure:
/// two seed numbers → upper/lower trigram names + 3-yao binaries + wuxing,
/// plus a moving-yao index. Random per-particle angles give the bursts variety.
class _RitualParams {
  final int n1; // upper trigram number (上卦数)
  final int n2; // lower trigram number (下卦数)
  final String upName; // upper trigram name
  final String loName; // lower trigram name
  final int upBin; // upper trigram 3-yao binary (0..7, bit0 = initial yao)
  final int loBin; // lower trigram 3-yao binary
  final String upWuxing; // upper trigram wuxing (金/木/水/火/土)
  final String loWuxing; // lower trigram wuxing
  final int dong; // moving yao 1..6 (1 = 初爻 / bottom)
  final List<double> burstAngles1; // impact burst particle angles for n1
  final List<double> burstAngles2; // impact burst particle angles for n2
  final List<double> dissolveAngles1; // dissolve particle angles for n1
  final List<double> dissolveAngles2; // dissolve particle angles for n2
  final List<double> dissolveSpeeds1; // per-particle radial speed multiplier
  final List<double> dissolveSpeeds2;

  _RitualParams({
    required this.n1,
    required this.n2,
    required this.upName,
    required this.loName,
    required this.upBin,
    required this.loBin,
    required this.upWuxing,
    required this.loWuxing,
    required this.dong,
    required this.burstAngles1,
    required this.burstAngles2,
    required this.dissolveAngles1,
    required this.dissolveAngles2,
    required this.dissolveSpeeds1,
    required this.dissolveSpeeds2,
  });

  factory _RitualParams.random() {
    final rng = math.Random();
    // Per design the seed numbers are in 1..9.
    final n1 = rng.nextInt(9) + 1;
    final n2 = rng.nextInt(9) + 1;

    // 先天八卦序: 1..8 → 乾兑离震巽坎艮坤.
    const xiantian = ['乾', '兑', '离', '震', '巽', '坎', '艮', '坤'];
    const nameToBin = {
      '坤': 0, '震': 1, '坎': 2, '兑': 3,
      '艮': 4, '离': 5, '巽': 6, '乾': 7,
    };
    const wuxing = {
      '乾': '金', '坤': '土', '震': '木', '巽': '木',
      '坎': '水', '离': '火', '艮': '土', '兑': '金',
    };

    final upName = xiantian[(n1 - 1) % 8];
    final loName = xiantian[(n2 - 1) % 8];
    // Moving yao: (n1 + n2) % 6 + 1, range 1..6.
    final dong = ((n1 + n2) % 6) + 1;

    List<double> angles(int count) => [
      for (var i = 0; i < count; i++) rng.nextDouble() * 2 * math.pi,
    ];
    List<double> speeds(int count) => [
      for (var i = 0; i < count; i++) 0.6 + rng.nextDouble() * 0.6,
    ];

    return _RitualParams(
      n1: n1,
      n2: n2,
      upName: upName,
      loName: loName,
      upBin: nameToBin[upName]!,
      loBin: nameToBin[loName]!,
      upWuxing: wuxing[upName]!,
      loWuxing: wuxing[loName]!,
      dong: dong,
      burstAngles1: angles(16),
      burstAngles2: angles(16),
      dissolveAngles1: angles(18),
      dissolveAngles2: angles(18),
      dissolveSpeeds1: speeds(18),
      dissolveSpeeds2: speeds(18),
    );
  }
}

class _MeihuaRitualPainter extends CustomPainter {
  final double t; // overall progress 0..1
  final _RitualParams p;

  _MeihuaRitualPainter(this.t, this.p);

  @override
  bool shouldRepaint(covariant _MeihuaRitualPainter old) => true;

  /// Sub-interval progress within [a, b], clamped to 0..1.
  double _iv(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  /// easeIn (accelerating) for falling.
  double _easeIn(double x) => x * x;

  /// easeOut (decelerating) for landing / line appearance.
  double _easeOut(double x) => 1 - math.pow(1 - x, 3).toDouble();

  // —— Layout constants ——
  static const double _lineW = 130.0;
  static const double _lineH = 5.0;
  static const double _lineGap = 14.0; // gap within a trigram
  static const double _trigramGap = 30.0; // gap between upper & lower trigram
  static const double _numFontSize = 44.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // Stack the 6-yao hexagram slightly above center to leave room for title.
    final stackCenterY = size.height * 0.46;
    final ys = _yaoY(stackCenterY);
    final upperCenterY = ys[4]; // middle of upper trigram (yao 5)
    final lowerCenterY = ys[1]; // middle of lower trigram (yao 2)

    // Phase 1: ambient + faint watermark.
    _drawAmbient(canvas, size, cx, stackCenterY);
    _drawWatermark(canvas, size, _iv(0.0, 0.4));

    // Phase 1-2: numbers fall (0.00-0.15) then impact (0.15-0.40).
    _drawNumbers(canvas, cx, upperCenterY, lowerCenterY);

    // Phase 3: dissolve into five-element light (0.40-0.70).
    _drawDissolve(canvas, cx, upperCenterY, lowerCenterY);

    // Phase 3: trigram yao lines fade in (0.45-0.72).
    _drawHexagram(canvas, cx, ys);

    // Phase 4: moving yao descends (0.75-0.95).
    _drawMovingYao(canvas, cx, ys);

    // Phase 5: golden border trace + title (0.95-1.00).
    _drawBorderAndTitle(canvas, size, cx, ys);
  }

  /// Compute y positions for the 6 yao (0 = bottom / 初爻 .. 5 = top / 上爻),
  /// centered around [stackCenterY]. The lower trigram (yao 0,1,2) sits below,
  /// the upper trigram (yao 3,4,5) above, separated by [_trigramGap].
  List<double> _yaoY(double stackCenterY) {
    final normal = _lineH + _lineGap;
    final big = _lineH + _trigramGap;
    // yao 2 (top of lower) just below center, yao 3 (bottom of upper) just above.
    final y2 = stackCenterY + big / 2;
    final y3 = stackCenterY - big / 2;
    return [
      y2 + 2 * normal, // 0 bottom (yao 1, 初爻)
      y2 + 1 * normal, // 1 (yao 2)
      y2, // 2 (yao 3, top of lower trigram)
      y3, // 3 (yao 4, bottom of upper trigram)
      y3 - 1 * normal, // 4 (yao 5)
      y3 - 2 * normal, // 5 top (yao 6, 上爻)
    ];
  }

  /// Whether yao k (0 = bottom .. 5 = top) is yang (solid).
  bool _isYang(int k) {
    if (k < 3) return ((p.loBin >> k) & 1) == 1;
    return ((p.upBin >> (k - 3)) & 1) == 1;
  }

  // —— Phase 1: ambient glow + watermark ——

  void _drawAmbient(Canvas canvas, Size size, double cx, double cy) {
    final a = _iv(0.0, 0.15);
    if (a <= 0) return;
    final r = size.shortestSide * 0.5;
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: a * 0.06),
            AppColors.gold.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
  }

  void _drawWatermark(Canvas canvas, Size size, double progress) {
    if (progress <= 0) return;
    _drawText(
      canvas,
      '梅花易数',
      Offset(size.width / 2, size.height / 2),
      TextStyle(
        color: AppColors.gold.withValues(alpha: progress * 0.05),
        fontSize: size.shortestSide * 0.22,
        fontWeight: AppFontWeight.bold,
        letterSpacing: AppLetterSpacing.ritualDisplay,
      ),
    );
  }

  // —— Phase 1-2: falling numbers + impact ——

  void _drawNumbers(
    Canvas canvas,
    double cx,
    double upperY,
    double lowerY,
  ) {
    final fallT = _iv(0.0, 0.15);
    final dissolveFade = _iv(0.40, 0.55);

    // Number alpha: quick fade-in at start, hold, then fade out during dissolve.
    double numAlpha = 1.0;
    if (t < 0.03) {
      numAlpha = (t / 0.03).clamp(0.0, 1.0);
    } else if (t > 0.40) {
      numAlpha = 1.0 - dissolveFade;
    }
    if (numAlpha <= 0) return;

    final fallE = _easeIn(fallT.clamp(0.0, 1.0));
    _drawFallingNumber(
      canvas, p.n1, cx, upperY, fallE, fallT, numAlpha, true,
    );
    _drawFallingNumber(
      canvas, p.n2, cx, lowerY, fallE, fallT, numAlpha, false,
    );
  }

  void _drawFallingNumber(
    Canvas canvas,
    int num,
    double cx,
    double landY,
    double fallE,
    double fallT,
    double alpha,
    bool fromLeft,
  ) {
    final startY = -40.0;
    final startX = fromLeft ? cx - 90.0 : cx + 90.0;
    final curX = ui.lerpDouble(startX, cx, fallE)!;
    final curY = ui.lerpDouble(startY, landY, fallE)!;

    // Slight rotation during the fall, opposing directions for variety.
    final rot = (fromLeft ? 1.0 : -1.0) * fallT * 0.6;

    // Scale: grow 0.8 → 1.0 while falling, then impact punch on landing.
    double scale = 0.8 + 0.2 * fallT;
    final impactT = _iv(0.15, 0.40);
    if (impactT > 0) {
      final punchT = (impactT / 0.30).clamp(0.0, 1.0);
      if (punchT < 1.0) {
        scale = punchT < 0.5
            ? ui.lerpDouble(1.0, 1.25, punchT / 0.5)!
            : ui.lerpDouble(1.25, 1.0, (punchT - 0.5) / 0.5)!;
      } else {
        scale = 1.0;
      }
      // Impact burst at the landing point (behind the number).
      if (impactT < 1.0) {
        _drawImpactBurst(
          canvas, cx, landY, impactT,
          fromLeft ? p.burstAngles1 : p.burstAngles2,
        );
      }
    }

    canvas.save();
    canvas.translate(curX, curY);
    canvas.rotate(rot);
    canvas.scale(scale);
    _drawText(
      canvas,
      '$num',
      Offset.zero,
      TextStyle(
        color: AppColors.goldBright.withValues(alpha: alpha),
        fontSize: _numFontSize,
        fontWeight: AppFontWeight.bold,
      ),
    );
    canvas.restore();
  }

  void _drawImpactBurst(
    Canvas canvas,
    double cx,
    double cy,
    double impactT,
    List<double> angles,
  ) {
    final e = _easeOut(impactT);
    // Radial glow flash.
    final glowR = 50.0 * e;
    canvas.drawCircle(
      Offset(cx, cy),
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.goldBright.withValues(alpha: (1 - impactT) * 0.5),
            AppColors.gold.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowR)),
    );
    // 16 golden particles radiating outward, fading.
    const count = 16;
    for (var i = 0; i < count; i++) {
      final angle = angles[i];
      final dist = 70.0 * e;
      final px = cx + dist * math.cos(angle);
      final py = cy + dist * math.sin(angle);
      canvas.drawCircle(
        Offset(px, py),
        2.5 * (1 - impactT * 0.5),
        Paint()
          ..color = AppColors.goldBright.withValues(alpha: (1 - impactT) * 0.8),
      );
    }
  }

  // —— Phase 3: dissolve into five-element light ——

  void _drawDissolve(
    Canvas canvas,
    double cx,
    double upperY,
    double lowerY,
  ) {
    final dT = _iv(0.40, 0.70);
    if (dT <= 0 || dT >= 1) return;
    _drawDissolveBurst(
      canvas, cx, upperY, dT, p.upWuxing,
      p.dissolveAngles1, p.dissolveSpeeds1,
    );
    _drawDissolveBurst(
      canvas, cx, lowerY, dT, p.loWuxing,
      p.dissolveAngles2, p.dissolveSpeeds2,
    );
  }

  void _drawDissolveBurst(
    Canvas canvas,
    double cx,
    double cy,
    double dT,
    String wuxing,
    List<double> angles,
    List<double> speeds,
  ) {
    final color = _wuxingGlow(wuxing);
    final e = _easeOut(dT);
    const count = 18;
    for (var i = 0; i < count; i++) {
      final angle = angles[i];
      final dist = 90.0 * e * speeds[i];
      final px = cx + dist * math.cos(angle);
      final py = cy + dist * math.sin(angle);
      canvas.drawCircle(
        Offset(px, py),
        3.0 * (1 - dT * 0.4),
        Paint()..color = color.withValues(alpha: (1 - dT) * 0.7),
      );
    }
  }

  /// Five-element (五行) glow color for a wuxing label.
  Color _wuxingGlow(String wuxing) {
    switch (wuxing) {
      case '金':
        return AppColors.metalGlow;
      case '木':
        return AppColors.woodGlow;
      case '水':
        return AppColors.waterGlow;
      case '火':
        return AppColors.fireGlow;
      case '土':
        return AppColors.earthGlow;
      default:
        return AppColors.goldBright;
    }
  }

  // —— Phase 3: hexagram yao lines + trigram labels ——

  void _drawHexagram(Canvas canvas, double cx, List<double> ys) {
    // Lower trigram fades in slightly ahead of the upper trigram.
    for (var k = 0; k < 6; k++) {
      final start = k < 3 ? 0.45 : 0.48;
      final yT = _iv(start, start + 0.20);
      if (yT <= 0) continue;
      _drawYao(canvas, cx, ys[k], _isYang(k), _easeOut(yT));
    }

    // Trigram name labels appear once the lines have mostly formed.
    final labelT = _iv(0.55, 0.72);
    if (labelT > 0) {
      final style = TextStyle(
        color: AppColors.goldBright.withValues(alpha: labelT * 0.7),
        fontSize: AppFontSize.bodyLarge,
        fontWeight: AppFontWeight.medium,
        letterSpacing: AppLetterSpacing.subtle,
      );
      _drawText(canvas, p.upName, Offset(cx + _lineW / 2 + 26, ys[4]), style);
      _drawText(canvas, p.loName, Offset(cx + _lineW / 2 + 26, ys[1]), style);
    }
  }

  /// Draw one yao line centered at (cx, y). Yang = solid bar; yin = two bars.
  void _drawYao(
    Canvas canvas,
    double cx,
    double y,
    bool yang,
    double progress,
  ) {
    final alpha = progress.clamp(0.0, 1.0);
    if (alpha <= 0) return;
    // Slight scale-in from center for elegance.
    final scale = 0.6 + 0.4 * progress;
    final paint = Paint()
      ..color = AppColors.goldBright.withValues(alpha: alpha)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _lineH;
    if (yang) {
      final halfW = (_lineW / 2) * scale;
      canvas.drawLine(Offset(cx - halfW, y), Offset(cx + halfW, y), paint);
    } else {
      const gap = 14.0;
      final barW = (_lineW - gap) / 2;
      final halfBar = (barW / 2) * scale;
      final midOffset = gap / 2 + barW / 2;
      canvas.drawLine(
        Offset(cx - midOffset - halfBar, y),
        Offset(cx - midOffset + halfBar, y),
        paint,
      );
      canvas.drawLine(
        Offset(cx + midOffset - halfBar, y),
        Offset(cx + midOffset + halfBar, y),
        paint,
      );
    }
  }

  // —— Phase 4: moving yao (动爻) descends ——

  void _drawMovingYao(Canvas canvas, double cx, List<double> ys) {
    final mT = _iv(0.75, 0.95);
    if (mT <= 0) return;
    final dongIdx = p.dong - 1; // 0..5
    final targetY = ys[dongIdx];

    // First half: a golden beam descends from the top to the moving yao.
    final descendT = (mT / 0.5).clamp(0.0, 1.0);
    if (descendT < 1.0) {
      final e = _easeOut(descendT);
      final beamY = ui.lerpDouble(-30.0, targetY, e)!;
      final beamAlpha = 0.55 * (1 - descendT * 0.3);
      canvas.drawLine(
        Offset(cx, -30),
        Offset(cx, beamY),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(cx, -30),
            Offset(cx, beamY),
            [
              AppColors.gold.withValues(alpha: 0),
              AppColors.goldBright.withValues(alpha: beamAlpha),
            ],
          )
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round,
      );
      // Leading glow head.
      canvas.drawCircle(
        Offset(cx, beamY),
        9.0,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.goldBright.withValues(alpha: beamAlpha),
              AppColors.gold.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, beamY), radius: 9),
          ),
      );
    }

    // After the beam lands: golden glow halo + brighter core on the dong yao.
    final glowT = _iv(0.83, 0.95);
    if (glowT > 0) {
      final gAlpha = _easeOut(glowT);
      final yang = _isYang(dongIdx);
      final halfW = _lineW / 2;

      // Halo behind the yao.
      final rect = Rect.fromCenter(
        center: Offset(cx, targetY),
        width: _lineW + 28,
        height: _lineH + 18,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.compactRound)),
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.goldBright.withValues(alpha: gAlpha * 0.38),
              AppColors.gold.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
      // Brighter, thicker golden core to mark the moving yao.
      _strokeYao(
        canvas,
        cx,
        targetY,
        yang,
        halfW,
        Paint()
          ..color = AppColors.goldLight.withValues(alpha: gAlpha)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = _lineH + 1.5,
      );
      // "动" marker to the left of the yao.
      _drawText(
        canvas,
        '动',
        Offset(cx - halfW - 22, targetY),
        TextStyle(
          color: AppColors.goldBright.withValues(alpha: gAlpha),
          fontSize: AppFontSize.bodySmall,
          fontWeight: AppFontWeight.bold,
        ),
      );
    }
  }

  /// Stroke a yao line (yang = solid, yin = broken) at full width.
  void _strokeYao(
    Canvas canvas,
    double cx,
    double y,
    bool yang,
    double halfW,
    Paint paint,
  ) {
    if (yang) {
      canvas.drawLine(Offset(cx - halfW, y), Offset(cx + halfW, y), paint);
    } else {
      const gap = 14.0;
      final barW = (_lineW - gap) / 2;
      final midOffset = gap / 2 + barW / 2;
      canvas.drawLine(
        Offset(cx - midOffset - barW / 2, y),
        Offset(cx - midOffset + barW / 2, y),
        paint,
      );
      canvas.drawLine(
        Offset(cx + midOffset - barW / 2, y),
        Offset(cx + midOffset + barW / 2, y),
        paint,
      );
    }
  }

  // —— Phase 5: golden border trace + title ——

  void _drawBorderAndTitle(
    Canvas canvas,
    Size size,
    double cx,
    List<double> ys,
  ) {
    final borderT = _iv(0.95, 1.0);
    if (borderT > 0) {
      const pad = 22.0;
      final top = ys[5] - _lineH / 2 - pad;
      final bottom = ys[0] + _lineH / 2 + pad;
      final left = cx - _lineW / 2 - pad;
      final right = cx + _lineW / 2 + pad;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom),
        const Radius.circular(AppRadius.control),
      );
      // Soft fill glow.
      canvas.drawRRect(
        rect,
        Paint()..color = AppColors.gold.withValues(alpha: borderT * 0.06),
      );
      // Golden border.
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.gold.withValues(alpha: borderT * 0.7)
          ..strokeWidth = 1.5,
      );
    }

    final titleT = _iv(0.96, 1.0);
    if (titleT > 0) {
      _drawText(
        canvas,
        '梅花易数',
        Offset(cx, size.height * 0.85),
        TextStyle(
          color: AppColors.goldBright.withValues(alpha: titleT),
          fontSize: AppFontSize.metric,
          fontWeight: AppFontWeight.bold,
          letterSpacing: AppLetterSpacing.ritual,
        ),
      );
    }
  }

  // —— Text helper (always disposes TextPainter — project hard rule) ——

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
