// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:jeenith/core/theme/app_theme.dart';

/// 墨晕开揭示动画组件。
///
/// 用 ShaderMask + RadialGradient 从中心向外扩散，
/// 子组件从「隐藏」到「显现」，模拟墨在纸上晕开的效果。
///
/// 用法：
/// ```dart
/// InkSpread(
///   duration: Duration(milliseconds: 800),
///   child: HexagramWidget(...),
/// )
/// ```
class InkSpread extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? inkColor;
  final bool autoStart;
  final VoidCallback? onComplete;

  const InkSpread({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.inkColor,
    this.autoStart = true,
    this.onComplete,
  });

  @override
  State<InkSpread> createState() => _InkSpreadState();
}

class _InkSpreadState extends State<InkSpread>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.autoStart) {
      _ctrl.forward().then((_) => widget.onComplete?.call());
    }
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
      builder: (context, child) {
        final p = _ctrl.value;
        // ShaderMask：从中心向外，0→1 的径向渐变
        return ShaderMask(
          shaderCallback: (rect) {
            final radius = (rect.longestSide * 0.7) * p;
            return RadialGradient(
              center: Alignment.center,
              radius: radius / (rect.longestSide * 0.7),
              colors: [
                AppColors.paperWhite,
                AppColors.paperWhite.withValues(alpha: p.clamp(0.0, 1.0)),
                AppColors.transparent,
              ],
              stops: [0.0, p.clamp(0.0, 1.0), 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 缩放揭示动画——从中心缩放放大 + 透明度渐入。
///
/// 用于结果图片、卦象等从中心揭示的场景。
class ScaleReveal extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double beginScale;
  final bool autoStart;
  final VoidCallback? onComplete;

  const ScaleReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.beginScale = 0.7,
    this.autoStart = true,
    this.onComplete,
  });

  @override
  State<ScaleReveal> createState() => _ScaleRevealState();
}

class _ScaleRevealState extends State<ScaleReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _scale = Tween<double>(
      begin: widget.beginScale,
      end: 1.0,
    ).animate(curve);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    if (widget.autoStart) {
      _ctrl.forward().then((_) => widget.onComplete?.call());
    }
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
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}
