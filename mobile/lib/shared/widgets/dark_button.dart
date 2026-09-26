// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/config_providers.dart';
import '../../core/theme/animations.dart';
import '../../core/theme/app_theme.dart';

/// Secondary surface button with an optional leading icon.
///
/// v2.0.0 升级：与 [GoldButton] 同款按动 0.95 缩放 + 阴影变化 + 抬起 easeOutBack 弹回。
/// The historical class name is retained for call-site compatibility; both
/// themes use the shared surface and text colors instead of the previous purple
/// gradient.
///
/// 内部自动读 [AppConfig.animationsEnabled]，开关关闭时降级为静态按钮。
class DarkButton extends ConsumerStatefulWidget {
  final String text;
  final Widget? icon;

  /// 自定义文字内容（优先于 [text]，自动套用按钮标签样式）。用于需要文字
  /// 过渡动画的场景（如 CopyResultButton「复制结果」→「已复制」切换）。
  final Widget? label;
  final VoidCallback? onPressed;
  final double radius;

  const DarkButton({
    super.key,
    required this.text,
    this.icon,
    this.label,
    this.onPressed,
    this.radius = AppRadius.button,
  });

  @override
  ConsumerState<DarkButton> createState() => _DarkButtonState();
}

class _DarkButtonState extends ConsumerState<DarkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  bool _down = false;
  // 最近一次 build 时确定的动画开关，供 tap 回调安全读取（避免在非 build
  // 上下文调用 ref.watch）。在 build 中通过 ref.watch 订阅以即时重建。
  bool _animEnabled = true;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppAnimations.pressDown),
      reverseDuration: const Duration(milliseconds: AppAnimations.pressRelease),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!_animEnabled || widget.onPressed == null) return;
    setState(() => _down = true);
    _press.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!_animEnabled) {
      widget.onPressed?.call();
      return;
    }
    setState(() => _down = false);
    _press.reverse().then((_) {
      if (mounted) widget.onPressed?.call();
    });
  }

  void _onTapCancel() {
    if (!_animEnabled) return;
    setState(() => _down = false);
    _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // 订阅全局配置：设置页切换开关时即时重建，动画/静态形态无缝切换
    _animEnabled =
        ref.watch(configProvider).valueOrNull?.animationsEnabled ?? true;
    final enabled = widget.onPressed != null;
    final animEnabled = _animEnabled;
    final c = AppClr.of(context);
    final labelColor = enabled ? c.textBody : c.textHint;
    final buttonColor = enabled ? c.buttonTop : c.panel;
    final borderColor = enabled
        ? c.goldBorder
        : c.goldBorder.withValues(alpha: 0.45);
    final labelStyle = context.appTypography.secondaryButton.copyWith(
      color: labelColor,
    );
    final label = widget.label != null
        ? DefaultTextStyle(style: labelStyle, child: widget.label!)
        : Text(widget.text, style: labelStyle);
    final innerContent = widget.icon == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme.merge(
                data: IconThemeData(size: 16, color: labelColor),
                child: widget.icon!,
              ),
              const SizedBox(width: 6),
              label,
            ],
          );

    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: borderColor),
        boxShadow: _down
            ? [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.06),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.06),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonSecondaryHorizontal,
          vertical: AppSpacing.buttonSecondaryVertical,
        ),
        child: innerContent,
      ),
    );

    final inner = animEnabled
        ? AnimatedBuilder(
            animation: _press,
            builder: (context, _) {
              final t = _press.value;
              final downCurve = AppAnimations.pressDownCurve.transform(t);
              final upCurve = AppAnimations.pressReleaseCurve.transform(1 - t);
              final scale = _down
                  ? 1.0 - 0.05 * downCurve
                  : 0.95 + 0.05 * upCurve;
              return Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: box,
              );
            },
          )
        : box;

    return GestureDetector(
      onTapDown: enabled ? _onTapDown : null,
      onTapUp: enabled ? _onTapUp : null,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: inner,
    );
  }
}
