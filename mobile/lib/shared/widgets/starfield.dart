// Copyright (c) 2026 Qore
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jeenith/core/theme/app_theme.dart';

/// 全局背景星尘：缓慢漂浮 + 闪烁的金色微粒，渲染于所有页面底层。
///
/// 监听 AppLifecycleState：应用进入后台/非活跃态时暂停动画，
/// 回到前台时恢复，避免后台仍持续 60fps 渲染消耗电量。
class Starfield extends StatefulWidget {
  final int count;
  final bool isLight;
  const Starfield({super.key, this.count = 64, this.isLight = false});

  @override
  State<Starfield> createState() => _StarfieldState();
}

class _StarfieldState extends State<Starfield>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ctrl;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final rnd = math.Random(2026);
    _stars = List.generate(widget.count, (_) => _Star.random(rnd));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    if (!_isAppInactive) _ctrl.repeat();
  }

  bool get _isAppInactive {
    final state = WidgetsBinding.instance.lifecycleState;
    return state != null && state != AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_ctrl.isAnimating) _ctrl.repeat();
    } else {
      if (_ctrl.isAnimating) _ctrl.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _StarPainter(_stars, _ctrl.value, widget.isLight),
          child: const SizedBox.expand(),
        ),
      );
}

class _Star {
  final double x;      // 0..1 横向比例
  final double y;      // 0..1 基准纵向
  final double r;      // 半径
  final double phase;  // 闪烁相位
  final double freq;   // 闪烁频率
  final double drift;  // 每周期下落量
  const _Star(this.x, this.y, this.r, this.phase, this.freq, this.drift);

  factory _Star.random(math.Random rnd) => _Star(
        rnd.nextDouble(),
        rnd.nextDouble(),
        0.4 + rnd.nextDouble() * 1.6,
        rnd.nextDouble() * math.pi * 2,
        0.6 + rnd.nextDouble() * 1.8,
        0.05 + rnd.nextDouble() * 0.12,
      );
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t; // 0..1 循环
  final bool isLight;
  _StarPainter(this.stars, this.t, this.isLight);

  @override
  bool shouldRepaint(_StarPainter old) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // 浅色主题用深金色星点，深色主题用鎏金。
    final baseColor = isLight ? AppColorsLight.yang : AppColors.yang;
    for (final s in stars) {
      final yy = ((s.y + t * s.drift) % 1.0) * h;
      final xx = s.x * w;
      final tw = 0.35 +
          0.5 * (0.5 + 0.5 * math.sin(t * s.freq * 2 * math.pi + s.phase));
      canvas.drawCircle(
        Offset(xx, yy),
        s.r,
        Paint()..color = baseColor.withValues(alpha: tw * 0.55),
      );
    }
  }
}
