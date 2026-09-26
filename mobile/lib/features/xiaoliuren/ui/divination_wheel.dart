// Copyright (c) 2026 Qore
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../algorithm/divine.dart';
import '../data/palaces.dart';

/// 起卦相位。
enum _Phase { idle, ignite, walk }

/// 一根游走拖尾：[palace] 指向的宫位，[age] 为独立消失进度 0→1。
class _TrailSeg {
  final int palace;
  double age;
  _TrailSeg(this.palace, this.age);
}

/// 六宫圆形掐指盘：激发爆光 → 游走拖尾（沿线渐隐）→ 落点弹跳。
class DivinationWheel extends StatefulWidget {
  final void Function()? onDone;
  const DivinationWheel({super.key, this.onDone});

  @override
  State<DivinationWheel> createState() => DivinationWheelState();
}

class DivinationWheelState extends State<DivinationWheel> {
  static const double _radiusRatio = 0.40;
  static const int _stepDelay = 3;    // 50ms * 3 = 150ms / 步
  static const int _pauseDelay = 7;   // 落点停顿
  static const int _igniteFrames = 8; // 激发爆光帧数（8*50=400ms）
  static const double _trailFade = 0.06; // 每帧拖尾消失进度（~16帧≈0.8s 全消）

  _Phase _phase = _Phase.idle;
  int _igniteFrame = 0;

  int cursor = -1;
  final Set<int> lit = {};
  final Map<int, double> _litAnim = {}; // 宫 -> 落点弹跳进度 0..1
  final List<_TrailSeg> _trail = [];     // 指针拖尾，每根独立渐隐
  List<int> resultLands = [];
  List<int> path = [];
  Set<int> landPositions = {};
  int walkI = 0;
  int stepCounter = 0;
  int pulse = 0;
  Timer? _timer;

  void start(List<int> nums) {
    final d = divine(nums);
    path = d.path;
    resultLands = d.lands;
    landPositions = d.landPositions.toSet();
    walkI = 0;
    stepCounter = 0;
    lit.clear();
    _litAnim.clear();
    _trail.clear();
    cursor = -1;
    _phase = _Phase.ignite;
    _igniteFrame = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
    setState(() {});
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _phase = _Phase.idle;
    _igniteFrame = 0;
    cursor = -1;
    lit.clear();
    _litAnim.clear();
    _trail.clear();
    resultLands = [];
    path = [];
    landPositions = {};
    walkI = 0;
    setState(() {});
  }

  void _pushTrail(int palace) {
    if (palace == -1) return;
    _trail.add(_TrailSeg(palace, 0));
  }

  void _tick() {
    pulse++;
    // 每根拖尾独立推进消失进度
    for (final seg in _trail) {
      seg.age += _trailFade;
    }
    _trail.removeWhere((s) => s.age >= 1.0);

    if (_phase == _Phase.ignite) {
      _igniteFrame++;
      if (_igniteFrame >= _igniteFrames) {
        _phase = _Phase.walk;
        cursor = path.isEmpty ? -1 : path.first;
      }
    } else if (_phase == _Phase.walk) {
      // 推进落点弹跳进度
      for (final k in _litAnim.keys.toList()) {
        if (_litAnim[k]! < 1) {
          _litAnim[k] = (_litAnim[k]! + 0.12).clamp(0.0, 1.0);
        }
      }
      if (walkI < path.length) {
        stepCounter++;
        final need = landPositions.contains(walkI) ? _pauseDelay : _stepDelay;
        if (stepCounter >= need) {
          stepCounter = 0;
          if (landPositions.contains(walkI)) {
            lit.add(path[walkI]);
            _litAnim[path[walkI]] = 0;
          }
          _pushTrail(cursor);
          walkI++;
          if (walkI < path.length) {
            cursor = path[walkI];
          } else {
            cursor = resultLands.isEmpty ? -1 : resultLands.last;
            _phase = _Phase.idle; // 不立即停，让拖尾继续渐隐
            widget.onDone?.call();
          }
        }
      }
    }

    // 游走结束且拖尾全部消散 → 停止重绘（盘面静止）
    if (_phase == _Phase.idle && _trail.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _WheelPainter(this, AppClr.of(context)), child: const SizedBox.expand());
}

class _WheelPainter extends CustomPainter {
  final DivinationWheelState s;
  final AppClr clr;
  _WheelPainter(this.s, this.clr);

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => true;

  /// 落点弹跳包络：t 0→1 时从 0 冲到峰值再回落到 0（叠加在固定放大倍率之上）。
  double _overshoot(double t) =>
      0.35 * math.sin(math.pi * t) * (1 - t * 0.4);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final R = math.min(w, h) * DivinationWheelState._radiusRatio;
    final breath = 0.5 + 0.5 * math.sin(s.pulse * 0.12);
    final c = clr;

    // —— 背景径向渐变（深色：紫黑；浅色：浅米，随主题切换）——
    final bgRect = Rect.fromCircle(center: Offset(cx, cy), radius: math.max(w, h) * 0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.large)),
      Paint()
        ..shader = RadialGradient(colors: [
          c.bgInner, c.bgMid, c.bgOuter,
        ]).createShader(bgRect),
    );

    // —— 外装饰金环 ——
    for (final r in [R + 70, R + 52, R + 38]) {
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = c.gold.withValues(alpha: 0.15)
          ..strokeWidth = 1,
      );
    }

    // —— 刻度（外环 48），卜算时旋转（idle 静止）——
    final tickSpin = s._phase == _Phase.idle ? 0.0 : s.pulse * 0.015;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(tickSpin);
    for (var k = 0; k < 48; k++) {
      canvas.rotate(2 * math.pi / 48);
      final major = k % 4 == 0;
      canvas.drawLine(
        Offset(R + 60, 0),
        Offset(R + (major ? 52 : 56), 0),
        Paint()
          ..color = c.gold.withValues(alpha: major ? 0.35 : 0.16)
          ..strokeWidth = major ? 2 : 1,
      );
    }
    canvas.restore();

    // —— 连接环（淡金虚线圆，用点近似）——
    canvas.drawCircle(
      Offset(cx, cy),
      R,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = c.gold.withValues(alpha: 0.22)
        ..strokeWidth = 1.5,
    );

    // —— 中心太极 ——
    _drawTaiji(canvas, Offset(cx, cy), R * 0.34);

    // —— 激发爆光（起卦瞬间从太极中心向外扩散）——
    if (s._phase == _Phase.ignite) {
      final p = s._igniteFrame / DivinationWheelState._igniteFrames;
      final radius = R * 0.34 + R * 1.3 * p;
      final alpha = (1 - p) * 0.7;
      // 深色用亮米白 0xFFFFF0C0；浅色用 gold 0xFFD4A857 以保证可见
      final igniteHot = c.sparkIgnite;
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..shader = RadialGradient(colors: [
            igniteHot.withValues(alpha: alpha),
            c.gold.withValues(alpha: alpha * 0.4),
            c.gold.withValues(alpha: 0),
          ]).createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: radius)),
      );
    }

    // —— 六宫节点 ——
    for (var i = 0; i < 6; i++) {
      final ang = -math.pi / 2 + (2 * math.pi / 6) * i;
      final pos = Offset(cx + R * math.cos(ang), cy + R * math.sin(ang));
      final info = palaces[i];
      final isLit = s.lit.contains(i);
      final isCursor = i == s.cursor;
      double baseR = R * 0.20, r = baseR;
      if (isLit) {
        final prog = s._litAnim[i] ?? 1.0;
        r = baseR * (1.16 + _overshoot(prog));
      } else if (isCursor) {
        r = baseR * (1.05 + 0.05 * breath);
      }

      // 光环
      if (isLit || isCursor) {
        final glowR = r + 22 + 8 * breath;
        canvas.drawCircle(
          pos,
          glowR,
          Paint()
            ..shader = RadialGradient(colors: [
              info.glow.withValues(alpha: isLit ? 0.62 : 0.43),
              info.glow.withValues(alpha: 0),
            ]).createShader(Rect.fromCircle(center: pos, radius: glowR)),
        );
      }

      // 节点渐变填充（info.color 是五行色，主题感知由 palaces 数据驱动；
      // 这里仍用 AppColors.darker 计算暗版，浅色模式下五行色已通过 AppClr 切换）
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [
              isLit ? info.glow : AppColors.darker(info.color, 0.85),
              AppColors.darker(info.color, isLit ? 0.55 : 0.32),
            ],
          ).createShader(Rect.fromCircle(center: pos, radius: r)),
      );
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = isLit ? info.glow : c.gold.withValues(alpha: 0.47)
          ..strokeWidth = isLit ? 2.2 : 1.4,
      );

      // 宫名 + 五行方位
      _drawText(
        canvas,
        info.name,
        pos + Offset(0, -r * 0.2),
        TextStyle(
          color: isLit ? c.textHighlight : c.textPrimary,
          fontSize: r * 0.46,
          fontWeight: AppFontWeight.bold,
        ),
      );
      _drawText(
        canvas,
        '${info.wuxing}·${info.fangwei}',
        pos + Offset(0, r * 0.32),
        TextStyle(
          color: c.goldBright.withValues(alpha: 0.78),
          fontSize: math.max(7.0, r * 0.22),
        ),
      );
    }

    // —— 游走指针拖尾：每根独立，从圆心端向宫位端渐隐（如射出之光）——
    for (final seg in s._trail) {
      final ang = -math.pi / 2 + (2 * math.pi / 6) * seg.palace;
      final pos = Offset(cx + R * math.cos(ang), cy + R * math.sin(ang));
      _drawTrailSeg(canvas, Offset(cx, cy), pos, seg.age);
    }

    // —— 游走指针（当前，最亮）——
    if (s.cursor != -1) {
      final ang = -math.pi / 2 + (2 * math.pi / 6) * s.cursor;
      final cpos = Offset(cx + R * math.cos(ang), cy + R * math.sin(ang));
      // 深色用 0xFFFFE6A0 亮黄；浅色用 gold 0xFFD4A857
      final cursorHot = c.sparkCursor;
      canvas.drawCircle(
        Offset(cx, cy),
        4,
        Paint()..color = cursorHot,
      );
      canvas.drawLine(
        Offset(cx, cy),
        cpos,
        Paint()
          ..color = clr.sparkTrail.withValues(alpha: 0.55)
          ..strokeWidth = 2,
      );
      canvas.drawCircle(cpos, 5, Paint()..color = cursorHot);
    }
  }

  /// 画一根拖尾：沿线 [center]→[pos] 分段，随 [age] 从圆心端向宫位端渐隐。
  void _drawTrailSeg(Canvas canvas, Offset center, Offset pos, double age) {
    const segs = 20;
    const baseAlpha = 0.55;
    const fadeBand = 0.32; // 消失前沿过渡宽度
    final globalFade = 1 - age * 0.3;
    // 深色用 0xFFFFD782 暖黄；浅色用 gold
    final trailHot = clr.sparkTrail;
    for (var k = 0; k < segs; k++) {
      final tm = (k + 0.5) / segs; // 段中点：0=圆心端，1=宫位端
      final a = ((tm - (age - fadeBand)) / fadeBand).clamp(0.0, 1.0) *
          baseAlpha *
          globalFade;
      if (a <= 0.01) continue;
      final p0 = Offset.lerp(center, pos, k / segs)!;
      final p1 = Offset.lerp(center, pos, (k + 1) / segs)!;
      canvas.drawLine(
        p0,
        p1,
        Paint()
          ..color = trailHot.withValues(alpha: a)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }
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

  /// 太极图（叠加法，与 Python 修复版一致）。
  void _drawTaiji(Canvas canvas, Offset center, double r) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(s.pulse * 0.6 * math.pi / 180);

    // 太极两色：深色用浅米白 + 紫黑；浅色用深鎏金 + 深棕（保证与浅色背景对比）
    final white = clr.ritualTaijiLight.withValues(alpha: 0.94);
    final black = clr.ritualTaijiDark.withValues(alpha: 0.92);
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);

    // 整圆白底
    canvas.drawCircle(Offset.zero, r, Paint()..color = white);
    // 右半圆黑
    final half = Path()
      ..moveTo(0, -r)
      ..arcTo(rect, -math.pi / 2, math.pi, false)
      ..close();
    canvas.drawPath(half, Paint()..color = black);
    // 上小圆白 / 下小圆黑（构成 S 形）
    canvas.drawCircle(Offset(0, -r / 2), r / 2, Paint()..color = white);
    canvas.drawCircle(Offset(0, r / 2), r / 2, Paint()..color = black);
    // 鱼眼
    canvas.drawCircle(Offset(0, -r / 2), r * 0.14, Paint()..color = black);
    canvas.drawCircle(Offset(0, r / 2), r * 0.14, Paint()..color = white);

    canvas.restore();
  }
}
