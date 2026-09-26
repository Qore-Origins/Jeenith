// Copyright (c) 2026 Qore
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/palaces.dart';

/// 小六壬仪式入场动画：太极生六宫。
///
/// 时序（点卡片后，总时长 ~3.8s）：
///  1. 深色背景渐显（首页淡出）。
///  2. 太极图从中心由小变大、由隐变显，旋转先快后慢。
///  3. 多圈同心圆错峰展开，有顺时针有逆时针。
///  4. 六宫从太极中心「射出」，沿外圈绕行后归位：
///     - 第 1 个出现的宫位：6 宫中随机选一个、起始角随机、顺/逆随机，绕整整一圈；
///     - 第 k 个：绕 (6-k) 段（递减），沿同一方向依次归位。
class XiaoliurenRitual extends StatefulWidget {
  /// 动画播完的回调（通常用于导航到小六壬页）。
  final VoidCallback? onCompleted;

  const XiaoliurenRitual({super.key, this.onCompleted});

  @override
  State<XiaoliurenRitual> createState() => _XiaoliurenRitualState();
}

class _XiaoliurenRitualState extends State<XiaoliurenRitual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final _RitualParams _p;

  @override
  void initState() {
    super.initState();
    _p = _RitualParams.random();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..forward().then((_) => widget.onCompleted?.call());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => CustomPaint(
        painter: _RitualPainter(_ctrl.value, _p),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// 一次仪式的随机参数：首宫、起始角、方向。
class _RitualParams {
  final int startPalace;  // 0..5 第一个出场的宫位
  final double baseAngle; // 第一个宫位归位角度（弧度）
  final int direction;    // +1 顺时针 / -1 逆时针

  _RitualParams(this.startPalace, this.baseAngle, this.direction);

  factory _RitualParams.random() {
    final rng = math.Random();
    return _RitualParams(
      rng.nextInt(6),
      rng.nextDouble() * 2 * math.pi,
      rng.nextBool() ? 1 : -1,
    );
  }
}

class _RitualPainter extends CustomPainter {
  final double t; // 总进度 0..1
  final _RitualParams p;
  _RitualPainter(this.t, this.p);

  @override
  bool shouldRepaint(covariant _RitualPainter old) => true;

  double _iv(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
  double _easeOut(double x) => 1 - math.pow(1 - x, 3).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final R = math.min(size.width, size.height) * 0.34;

    // 1. 背景：0.00-0.12 渐显
    final bgA = _iv(0.0, 0.12);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.ritualBackground.withValues(alpha: bgA),
    );

    // 2. 太极：0.06-0.30 缩放 + 显隐 + 旋转（先快后慢）
    final tt = _iv(0.06, 0.30);
    if (tt > 0) {
      final e = _easeOut(tt);
      final scale = ui.lerpDouble(0.06, 1.0, e)!;
      final alpha = tt;
      final rot = (1 - e) * 6 * math.pi; // 剩余角度递减 → 先快后慢
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(scale);
      canvas.rotate(rot);
      _drawTaiji(canvas, R * 0.30, alpha);
      canvas.restore();
    }

    // 3. 罗盘环：0.20-0.55，4 圈错峰，交替顺逆（金环 + 周边刻度）
    for (var i = 0; i < 4; i++) {
      final rt = _iv(0.20 + i * 0.05, 0.50 + i * 0.05);
      if (rt <= 0) continue;
      final e = _easeOut(rt.clamp(0.0, 1.0));
      final rr = R * (0.55 + i * 0.16) * e;
      final alpha = rt.clamp(0.0, 1.0) * 0.55;
      final dir = i.isEven ? 1 : -1;
      final rot = (1 - rt) * 2 * math.pi * dir;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot);
      // 罗盘金环
      canvas.drawCircle(
        Offset.zero,
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.gold.withValues(alpha: alpha)
          ..strokeWidth = 1.2,
      );
      // 罗盘刻度（沿环外侧，每 15° 一格，主刻度更粗）
      const tickCount = 24;
      for (var k = 0; k < tickCount; k++) {
        final ang = k * 2 * math.pi / tickCount;
        final major = k % 6 == 0;
        final ca = math.cos(ang);
        final sa = math.sin(ang);
        final tickLen = rr * (major ? 0.05 : 0.03);
        canvas.drawLine(
          Offset(rr * ca, rr * sa),
          Offset((rr + tickLen) * ca, (rr + tickLen) * sa),
          Paint()
            ..color = AppColors.gold
                .withValues(alpha: alpha * (major ? 0.9 : 0.5))
            ..strokeWidth = major ? 1.2 : 0.6,
        );
      }
      canvas.restore();
    }

    // 4. 六宫归位：0.46-0.96，第 k 个错峰出场
    //    宫位 index = (startPalace + dir*k) mod 6
    //    目标角    = baseAngle + dir*k*60°
    //    绕行段数  = 6-k （第0个绕6段=360°，第5个绕1段=60°）
    //    先从中心「射出」到外圈起点，再沿外圈绕行到目标
    for (var k = 0; k < 6; k++) {
      final kT = _iv(0.46 + k * 0.05, 0.60 + k * 0.05);
      if (kT <= 0) continue;
      final palaceIdx = ((p.startPalace + p.direction * k) % 6 + 6) % 6;
      final info = palaces[palaceIdx];
      final targetAng = p.baseAngle + p.direction * k * (math.pi / 3);
      final segs = 6 - k;
      final startAng = targetAng - p.direction * segs * (math.pi / 3);

      double radius, ang, scale, alpha;
      if (kT < 0.35) {
        // 射出：中心 → 外圈起点（由小变大、由隐变显）
        final st = kT / 0.35;
        final e = _easeOut(st);
        radius = R * e;
        ang = startAng;
        scale = e;
        alpha = st;
      } else {
        // 绕行：沿外圈 startAng → targetAng
        final wt = (kT - 0.35) / 0.65;
        final e = _easeOut(wt);
        radius = R;
        ang = startAng + (targetAng - startAng) * e;
        scale = 1.0;
        alpha = 1.0;
      }

      final px = cx + radius * math.cos(ang);
      final py = cy + radius * math.sin(ang);
      final nodeR = R * 0.15 * scale;

      // 光环
      canvas.drawCircle(
        Offset(px, py),
        nodeR + 16,
        Paint()
          ..shader = RadialGradient(colors: [
            info.glow.withValues(alpha: alpha * 0.5),
            info.glow.withValues(alpha: 0),
          ]).createShader(
              Rect.fromCircle(center: Offset(px, py), radius: nodeR + 16)),
      );
      // 节点渐变填充
      canvas.drawCircle(
        Offset(px, py),
        nodeR,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [
              info.glow.withValues(alpha: alpha),
              AppColors.darker(info.color, 0.5).withValues(alpha: alpha),
            ],
          ).createShader(Rect.fromCircle(center: Offset(px, py), radius: nodeR)),
      );
      canvas.drawCircle(
        Offset(px, py),
        nodeR,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = info.glow.withValues(alpha: alpha)
          ..strokeWidth = 2,
      );
      // 宫名
      if (scale > 0.45) {
        _drawText(
          canvas,
          info.name,
          Offset(px, py),
          TextStyle(
            color: AppColors.textHighlight.withValues(alpha: alpha),
            fontSize: nodeR * 0.62,
            fontWeight: AppFontWeight.bold,
          ),
        );
      }
    }
  }

  /// 太极图（叠加法）。
  void _drawTaiji(Canvas canvas, double r, double alpha) {
    final white = AppColors.ritualTaijiLight.withValues(alpha: alpha * 0.94);
    final black = AppColors.ritualTaijiDark.withValues(alpha: alpha * 0.92);
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawCircle(Offset.zero, r, Paint()..color = white);
    final half = Path()
      ..moveTo(0, -r)
      ..arcTo(rect, -math.pi / 2, math.pi, false)
      ..close();
    canvas.drawPath(half, Paint()..color = black);
    canvas.drawCircle(Offset(0, -r / 2), r / 2, Paint()..color = white);
    canvas.drawCircle(Offset(0, r / 2), r / 2, Paint()..color = black);
    canvas.drawCircle(
        Offset(0, -r / 2), r * 0.14, Paint()..color = black);
    canvas.drawCircle(
        Offset(0, r / 2), r * 0.14, Paint()..color = white);
  }

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
