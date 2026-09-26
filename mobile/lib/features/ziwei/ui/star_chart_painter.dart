// Copyright (c) 2026 Qore
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../algorithm/divine.dart';
import '../algorithm/liu_nian.dart';
import '../algorithm/star_placement.dart';
import '../data/stars.dart';

/// 紫微斗数环形命盘绘制器。
///
/// 12 宫按地支 0-11 索引（子..亥）排列：子位于底部（6 点钟方向），
/// 逆时针布列（丑→寅→卯...），与紫微斗数传统排盘一致。
///
/// v2.3.1：新增 [progress]（0.0→1.0）参数驱动绘制过程动画。
/// - 0.0-0.55：12 宫按命宫→顺时针方向逐个绘制（每宫 100ms 错峰）
/// - 0.55-1.0：星曜按主星→辅星顺序逐颗降落（带淡入）
/// - progress = 1.0 时完全绘制（向后兼容）
class StarChartPainter extends CustomPainter {
  /// 命宫地支索引 0..11。
  final int mingGong;

  /// 身宫地支索引 0..11。
  final int shenGong;

  /// 按地支排列的宫名索引。
  final List<int> gongAtZhi;

  /// 命宫干支（如 "甲子"）。
  final String mingGanZhi;

  /// 五行局（如 "水二局"）。
  final String wuxingJu;

  /// 已排布的星曜分布。
  final StarChart chart;

  /// 流年/小限信息（v2.12.0）。非 null 时叠加流年命宫（红）/ 小限宫（蓝）高亮。
  final LiuNianInfo? liuNian;

  /// 绘制进度 0.0→1.0。1.0 表示完全绘制（默认）。
  final double progress;

  /// 主题感知色板（深↔浅插值）。
  final AppClr clr;

  const StarChartPainter({
    required this.mingGong,
    required this.shenGong,
    required this.gongAtZhi,
    required this.mingGanZhi,
    required this.wuxingJu,
    required this.chart,
    this.liuNian,
    this.progress = 1.0,
    required this.clr,
  });

  /// 局部进度（0..1）：从 [start] 到 [end] 区间。
  double _seg(double start, double end) =>
      ((progress - start) / (end - start)).clamp(0.0, 1.0);

  /// easeOut：先快后慢。
  double _easeOut(double t) {
    final x = t.clamp(0.0, 1.0);
    return 1 - (1 - x) * (1 - x) * (1 - x);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const dz = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(size.width, size.height) / 2 * 0.96;
    final innerR = outerR * 0.34;
    final midR = (innerR + outerR) / 2;

    // === 内外环（首帧绘制） ===
    final outerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = clr.gold;
    canvas.drawCircle(Offset(cx, cy), outerR, outerRingPaint);

    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = clr.goldBorder;
    canvas.drawCircle(Offset(cx, cy), innerR, innerRingPaint);

    // 中央圆背景（progress < 0.05 时不绘制，避免遮盖中心爆光）
    if (progress > 0.05) {
      final centerBgPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = clr.bgInner;
      canvas.drawCircle(Offset(cx, cy), innerR - 1, centerBgPaint);
    }

    // === 12 宫扇形：按命宫→顺时针逐个绘制（每宫错峰） ===
    // 命宫优先（gongIdx=0 即「命宫」），按地支顺时针方向展开。
    // 命宫为起点，从 mingGong 顺时针走 12 个位置。
    final drawOrder = <int>[];
    for (var i = 0; i < 12; i++) {
      drawOrder.add((mingGong + i) % 12);
    }
    // 12 宫绘制区间 0.0-0.55，每宫 ~0.046（约 55ms @1.2s 总时长）
    for (var orderIdx = 0; orderIdx < 12; orderIdx++) {
      final zhi = drawOrder[orderIdx];
      final gongStart = orderIdx * 0.045;
      final gongEnd = (orderIdx + 1) * 0.055;
      final localT = _easeOut(_seg(gongStart, gongEnd));
      if (localT <= 0.0) continue; // 未到该宫的绘制时机

      // 子位于底部（canvas 角度 π/2，因为 canvas Y 朝下），逆时针布列
      final centerAngle = math.pi / 2 + zhi * math.pi / 6;
      final halfSweep = math.pi / 12;
      final startAngle = centerAngle - halfSweep;
      final sweep = math.pi / 6;

      final isMing = zhi == mingGong;
      final isShen = zhi == shenGong;
      final isLiuNianMing = liuNian != null && zhi == liuNian!.zhiIdx;
      final isXiaoXian = liuNian != null && zhi == liuNian!.xiaoXianZhi;

      // 扇形背景（绘制时带 scale 入场效果）
      canvas.save();
      // 从中心放大归位
      final scale = 0.5 + 0.5 * localT;
      canvas.translate(cx, cy);
      canvas.scale(scale);
      canvas.translate(-cx, -cy);

      final path = Path()
        ..addArc(Rect.fromCircle(center: Offset(cx, cy), radius: outerR),
            startAngle, sweep)
        ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: innerR),
            startAngle + sweep, -sweep, false)
        ..close();

      final bgPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = (isLiuNianMing
                ? clr.fireGlow.withValues(alpha: 0.20)
                : (isXiaoXian
                    ? clr.waterDeepGlow.withValues(alpha: 0.20)
                    : (isMing
                        ? clr.gold.withValues(alpha: 0.20)
                        : (isShen
                            ? clr.waterDeep.withValues(alpha: 0.20)
                            : clr.card))))
            .withValues(alpha: localT);
      canvas.drawPath(path, bgPaint);

      // 描边（流年命宫红 / 小限蓝 / 本命命宫金 / 身宫水，优先级递减）
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            (isLiuNianMing || isXiaoXian || isMing || isShen) ? 1.6 : 0.6
        ..color = isLiuNianMing
            ? clr.fireGlow
            : (isXiaoXian
                ? clr.waterDeepGlow
                : (isMing
                    ? clr.gold
                    : (isShen ? clr.waterDeepGlow : clr.goldBorder)));
      canvas.drawPath(path, borderPaint);

      canvas.restore();

      // 文字（绘制完成宫位 60% 后开始显示）
      if (localT < 0.6) continue;
      final textAlpha = ((localT - 0.6) / 0.4).clamp(0.0, 1.0);

      // Text anchor at the sector radial midpoint.
      final mx = cx + midR * math.cos(centerAngle);
      final my = cy + midR * math.sin(centerAngle);

      canvas.save();
      canvas.translate(mx, my);
      canvas.rotate(centerAngle - math.pi / 2);

      // Earthly Branch（流年命宫红 / 小限蓝 / 本命命宫金亮）
      _drawText(
        canvas,
        dz[zhi],
        const Offset(0, -24),
        color: (isLiuNianMing
                ? clr.fireGlow
                : (isXiaoXian
                    ? clr.waterDeepGlow
                    : (isMing ? clr.goldBright : clr.textMeta)))
            .withValues(alpha: textAlpha),
        fontSize: AppFontSize.bodySmall,
        fontWeight: AppFontWeight.bold,
      );

      // Palace name
      final gongIdx = gongAtZhi[zhi];
      if (gongIdx >= 0 && gongIdx < palaceNames.length) {
        _drawText(
          canvas,
          palaceNames[gongIdx],
          const Offset(0, -9),
          color: (isMing ? clr.gold : clr.textPrimary)
              .withValues(alpha: textAlpha),
          fontSize: AppFontSize.micro,
          fontWeight: AppFontWeight.bold,
        );
      }

      canvas.restore();
    }

    // === 星曜：按主星→辅星顺序逐颗降落（带淡入）===
    // 0.55-1.0 区间，所有宫位星曜汇总后按主星优先级排序
    if (progress > 0.5) {
      // 收集所有星曜及其宫位角度，按主星优先级排序
      final allStars = <_StarDrawItem>[];
      for (var zhi = 0; zhi < 12; zhi++) {
        final stars = chart.gongStars[zhi];
        final centerAngle = math.pi / 2 + zhi * math.pi / 6;
        final mx = cx + midR * math.cos(centerAngle);
        final my = cy + midR * math.sin(centerAngle);
        var y = 6.0;
        for (final star in stars) {
          allStars.add(_StarDrawItem(
            name: star.name,
            category: star.category,
            sihua: star.sihua,
            anchorX: mx,
            anchorY: my,
            anchorAngle: centerAngle - math.pi / 2,
            offsetY: y,
          ));
          final fontSize = star.category == StarCategory.main ? 10.5 : 8.5;
          y += fontSize + 2;
        }
      }
      // 主星在前，其余按原顺序
      allStars.sort((a, b) {
        final aMain = a.category == StarCategory.main ? 0 : 1;
        final bMain = b.category == StarCategory.main ? 0 : 1;
        return aMain.compareTo(bMain);
      });

      final totalStars = allStars.length;
      // 0.5-1.0 区间内分摊，每颗错峰
      final perStar = 0.5 / math.max(totalStars, 1);
      for (var i = 0; i < totalStars; i++) {
        final s = allStars[i];
        final starStart = 0.5 + i * perStar;
        final starEnd = starStart + perStar * 2; // 每颗用 2 倍 perStar 完成淡入
        final t = _seg(starStart, starEnd);
        if (t <= 0.0) continue;
        final alpha = _easeOut(t);

        canvas.save();
        canvas.translate(s.anchorX, s.anchorY);
        canvas.rotate(s.anchorAngle);
        _drawStarText(canvas, s, alpha);
        canvas.restore();
      }
    }

    // === 中央信息（最后绘制，progress > 0.7 才显示） ===
    if (progress > 0.7) {
      final centerAlpha = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);

      // 太极圆点
      final taijiR = innerR * 0.18;
      final taijiPaint = Paint()
        ..color = clr.goldBright.withValues(alpha: centerAlpha);
      canvas.drawCircle(Offset(cx, cy - innerR * 0.45), taijiR, taijiPaint);
      final taijiBgPaint = Paint()
        ..color = clr.bgOuter.withValues(alpha: centerAlpha);
      canvas.drawCircle(
          Offset(cx, cy - innerR * 0.45), taijiR * 0.55, taijiBgPaint);

      // 命宫干支
      _drawText(
        canvas,
        mingGanZhi,
        Offset(cx, cy),
        color: clr.goldBright.withValues(alpha: centerAlpha),
        fontSize: AppFontSize.button,
        fontWeight: AppFontWeight.bold,
      );

      // 五行局
      _drawText(
        canvas,
        wuxingJu,
        Offset(cx, cy + innerR * 0.4),
        color: clr.fireGlow.withValues(alpha: centerAlpha),
        fontSize: AppFontSize.caption,
      );
    }
  }

  Color _categoryColor(StarCategory cat) {
    switch (cat) {
      case StarCategory.main:
        return clr.goldBright;
      case StarCategory.auspicious:
        return clr.woodGlow;
      case StarCategory.malefic:
        return clr.fireGlow;
      case StarCategory.boshishen:
        return clr.textSubtitle;
      case StarCategory.shensha:
        return clr.earthGlow;
    }
  }

  /// 四化角标配色：禄金 · 权火 · 科水 · 忌灰。
  Color _siHuaColor(SiHua sh) {
    switch (sh) {
      case SiHua.lu:
        return clr.gold;
      case SiHua.quan:
        return clr.fireGlow;
      case SiHua.ke:
        return clr.waterDeepGlow;
      case SiHua.ji:
        return clr.textSubtitle;
    }
  }

  /// 绘制星名 + 可选四化角标（紧贴右下，四色区分），富文本居中。
  /// 绘制后立即释放 TextPainter（项目硬约束）。
  void _drawStarText(Canvas canvas, _StarDrawItem s, double alpha) {
    final fontSize = s.category == StarCategory.main ? 10.5 : 8.5;
    final children = <TextSpan>[
      TextSpan(
        text: s.name,
        style: TextStyle(
          color: _categoryColor(s.category).withValues(alpha: alpha),
          fontSize: fontSize,
          fontWeight:
              s.category == StarCategory.main ? AppFontWeight.bold : AppFontWeight.regular,
        ),
      ),
      if (s.sihua != null)
        TextSpan(
          text: s.sihua!.label,
          style: TextStyle(
            color: _siHuaColor(s.sihua!).withValues(alpha: alpha),
            fontSize: fontSize - 2,
            fontWeight: AppFontWeight.bold,
          ),
        ),
    ];
    final tp = TextPainter(
      text: TextSpan(children: children),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, s.offsetY - tp.height / 2));
    tp.dispose();
  }

  /// 绘制居中文本，绘制后立即释放 TextPainter（项目硬约束）。
  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required Color color,
    required double fontSize,
    FontWeight fontWeight = AppFontWeight.regular,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    tp.dispose();
  }

  @override
  bool shouldRepaint(covariant StarChartPainter old) =>
      old.mingGong != mingGong ||
      old.shenGong != shenGong ||
      old.chart != chart ||
      old.mingGanZhi != mingGanZhi ||
      old.liuNian?.year != liuNian?.year ||
      old.liuNian?.zhiIdx != liuNian?.zhiIdx ||
      old.liuNian?.xiaoXianZhi != liuNian?.xiaoXianZhi ||
      old.progress != progress ||
      old.clr.t != clr.t;
}

/// 内部辅助：星曜绘制项（位置 + 分类 + 四化）。
class _StarDrawItem {
  final String name;
  final StarCategory category;
  final SiHua? sihua;
  final double anchorX;
  final double anchorY;
  final double anchorAngle;
  final double offsetY;

  const _StarDrawItem({
    required this.name,
    required this.category,
    this.sihua,
    required this.anchorX,
    required this.anchorY,
    required this.anchorAngle,
    required this.offsetY,
  });
}
