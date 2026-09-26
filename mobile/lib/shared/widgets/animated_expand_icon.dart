// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/config_providers.dart';
import '../../core/theme/animations.dart';
import '../../core/theme/app_theme.dart';

/// 图标状态切换动画（+ ↔ x / + ↔ -）。
///
/// v2.0.0 新增：列表折叠/展开、功能性动作的状态切换。
/// - 底层 [AnimatedRotation]：0° → [expandedAngle]，默认 90°（+ → x / 箭头朝下）。
/// - 点击瞬间 [AnimatedScale] 呼吸反馈：1.0 → 0.86 → 1.0。
///
/// 内部自动读 [AppConfig.animationsEnabled]，开关关闭时降级为静态 Icon，
/// 仅响应点击。调用方无需再传 `animationsEnabled`，避免重复传递与不一致。
///
/// 用法：
/// ```dart
/// AnimatedExpandIcon(
///   expanded: _opened,
///   onPressed: () => setState(() => _opened = !_opened),
/// )
/// ```
class AnimatedExpandIcon extends ConsumerStatefulWidget {
  final bool expanded;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final double expandedAngle;
  final IconData collapsedIcon;

  const AnimatedExpandIcon({
    super.key,
    required this.expanded,
    this.onPressed,
    this.color,
    this.size = 24,
    this.expandedAngle = 90,
    this.collapsedIcon = Icons.expand_more,
  });

  @override
  ConsumerState<AnimatedExpandIcon> createState() => _AnimatedExpandIconState();
}

class _AnimatedExpandIconState extends ConsumerState<AnimatedExpandIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;
  // 最近一次 build 时确定的动画开关，供 tap 回调安全读取（避免在非 build
  // 上下文调用 ref.watch）。在 build 中通过 ref.watch 订阅以即时重建。
  bool _animEnabled = true;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.iconScale),
      reverseDuration: const Duration(milliseconds: AppAnimations.iconScale),
    );
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_animEnabled) {
      _breath.forward().then((_) {
        if (mounted) _breath.reverse();
      });
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    // 订阅全局配置：设置页切换开关时即时重建，动画/静态形态无缝切换
    _animEnabled =
        ref.watch(configProvider).valueOrNull?.animationsEnabled ?? true;

    final iconColor =
        widget.color ?? IconTheme.of(context).color ?? AppClr.of(context).gold;

    final baseIcon = Icon(
      widget.collapsedIcon,
      color: iconColor,
      size: widget.size,
    );

    if (!_animEnabled) {
      return GestureDetector(
        onTap: widget.onPressed == null ? null : _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(padding: const EdgeInsets.all(8), child: baseIcon),
      );
    }

    return GestureDetector(
      onTap: widget.onPressed == null ? null : _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, _) {
          // 呼吸：1.0 → 0.86 → 1.0（按下塌缩 + 回弹，与按钮质感一致）
          final breathScale = 1.0 - 0.14 * _breath.value;
          return Transform.scale(
            scale: breathScale,
            child: AnimatedRotation(
              turns: widget.expanded ? widget.expandedAngle / 360 : 0,
              duration: const Duration(milliseconds: AppAnimations.iconRotate),
              curve: AppAnimations.iconRotateCurve,
              child: Padding(padding: const EdgeInsets.all(8), child: baseIcon),
            ),
          );
        },
      ),
    );
  }
}
