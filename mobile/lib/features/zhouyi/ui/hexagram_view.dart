// Copyright (c) 2026 Qore
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../algorithm/divine.dart';

/// 六爻图：6 爻从下到上，逐爻揭示，阳爻实线/阴爻断线/变爻红点。
class HexagramView extends StatefulWidget {
  final List<Line>? lines;
  final VoidCallback? onDone;
  const HexagramView({super.key, this.lines, this.onDone});

  @override
  State<HexagramView> createState() => _HexagramViewState();
}

class _HexagramViewState extends State<HexagramView> {
  int _revealed = 0;
  Timer? _t;

  @override
  void didUpdateWidget(covariant HexagramView old) {
    super.didUpdateWidget(old);
    if (widget.lines != null && widget.lines != old.lines) {
      _revealed = 0;
      _t?.cancel();
      _t = Timer.periodic(const Duration(milliseconds: 380), (_) {
        if (!mounted) return;
        if (_revealed < 6) {
          setState(() => _revealed++);
          if (_revealed == 6) {
            _t?.cancel();
            widget.onDone?.call();
          }
        }
      });
    } else if (widget.lines == null) {
      _t?.cancel();
      _revealed = 0;
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _HexPainter(widget.lines, _revealed, AppClr.of(context)),
        child: const SizedBox.expand(),
      );
}

const _posNames = ['初', '二', '三', '四', '五', '上'];

class _HexPainter extends CustomPainter {
  final List<Line>? lines;
  final int revealed;
  final AppClr clr;
  _HexPainter(this.lines, this.revealed, this.clr);

  @override
  bool shouldRepaint(_) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    final lineW = w * 0.66;
    final x0 = cx - lineW / 2, x1 = cx + lineW / 2;
    final spacing = h * 0.52 / 6;
    final baseY = h * 0.72;

    for (var i = 0; i < 6; i++) {
      final y = baseY - i * spacing;
      _drawText(canvas, _posNames[i], Offset(x0 - 18, y),
          TextStyle(color: clr.textMeta, fontSize: AppFontSize.caption),
          align: TextAlign.right);
      _drawText(canvas, _posNames[i], Offset(x1 + 18, y),
          TextStyle(color: clr.textMeta, fontSize: AppFontSize.caption));

      if (i >= revealed || lines == null) {
        // 占位：淡线
        canvas.drawLine(
          Offset(x0, y),
          Offset(x1, y),
          Paint()
            ..color = clr.gold.withValues(alpha: 0.12)
            ..strokeWidth = 1,
        );
        continue;
      }

      final line = lines![i];
      final color = line.changing
          ? clr.changing
          : (line.yang ? clr.yang : clr.yin);
      final p = Paint()
        ..color = color
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round;
      if (line.yang) {
        canvas.drawLine(Offset(x0, y), Offset(x1, y), p);
      } else {
        final gap = lineW * 0.13;
        canvas.drawLine(Offset(x0, y), Offset(cx - gap, y), p);
        canvas.drawLine(Offset(cx + gap, y), Offset(x1, y), p);
      }
      if (line.changing) {
        canvas.drawCircle(Offset(x0, y), 6.5, Paint()..color = color);
        canvas.drawCircle(Offset(x1, y), 6.5, Paint()..color = color);
      }
    }
  }

  void _drawText(Canvas c, String t, Offset pos, TextStyle s,
      {TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: s),
      textAlign: align,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final dx = align == TextAlign.right ? -tp.width : 0.0;
    tp.paint(c, pos + Offset(dx, -tp.height / 2));
    tp.dispose();
  }
}
