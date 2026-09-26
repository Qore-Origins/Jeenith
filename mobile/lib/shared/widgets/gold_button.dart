// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/config_providers.dart';
import '../../core/theme/animations.dart';
import '../../core/theme/app_theme.dart';

/// Primary action button using the shared jade theme color.
///
/// v2.0.0 升级：按动 0.95 缩放 + 阴影变化，抬起用 [AppAnimations.pressReleaseCurve]
/// （[Curves.easeOutBack] 变体）弹回——模拟物理弹性，质感来自曲线而非饱和度。
///
/// **v2.10.3 竖线坍塌第 5 次根治**（继 v2.3.1/v2.7.1/v2.10.0/v2.10.1 后第五次）：
/// v2.10.1 用 `ConstrainedBox(minWidth:88)` 单层结构防护了 loose/unbounded 场景，
/// 但遗漏了 **tight(W<88) 矛盾约束场景**：当父级 Expanded 在窄屏给 GoldButton 的
/// width < 88 时，`ConstrainedBox.enforce(tight(W<88))` 产出 tight(88) 给 child，
/// 但 ConstrainedBox.size 被 parent maxWidth=W<88 clamp 回 W（甚至 0），造成
/// size=0 / child=88 的撕裂，release 模式渲染降级为竖线。
/// 本次加 LayoutBuilder 防御层：检测到 tight(maxWidth<88) 矛盾时，放弃 minWidth:88
/// 强制，直接按可用宽度渲染 box（文字可能裁剪，但按钮本体可见可点击）。
/// - tight(W≥88) 下：走原 ConstrainedBox 分支，enforce 后 tight(W)，撑满 W
/// - loose(maxWidth=W≥88) 下：走原 ConstrainedBox 分支，box 按 intrinsic 测量
/// - loose unbounded(maxWidth=inf) 下：走原 ConstrainedBox 分支，minWidth 兜底
/// - tight(W<88) 矛盾下：**降级**，直接返回 box，按可用宽度渲染（防御层）
/// 详见频发 BUG 文档 `docs/频发BUG/GoldButton竖线坍塌.md`。
///
/// The historical class name is retained for call-site compatibility; its colors
/// follow the current theme instead of the previous bright gold gradient.
///
/// 内部自动读 [AppConfig.animationsEnabled]，开关关闭时降级为静态按钮。
class GoldButton extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double radius;

  const GoldButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.radius = AppRadius.button,
  });

  @override
  ConsumerState<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends ConsumerState<GoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  bool _down = false;
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

  @override
  Widget build(BuildContext context) {
    _animEnabled =
        ref.watch(configProvider).valueOrNull?.animationsEnabled ?? true;
    final enabled = widget.onPressed != null;
    final animEnabled = _animEnabled;
    final c = AppClr.of(context);
    final labelColor = enabled ? c.onAction : c.textHint;
    final buttonColor = enabled ? c.jade : c.panel;
    final borderColor = enabled ? c.jade : c.goldBorder.withValues(alpha: 0.55);

    final label = Text(
      widget.text,
      style: context.appTypography.button.copyWith(
        color: labelColor,
        fontWeight: AppFontWeight.bold,
      ),
    );
    final child = widget.icon == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: labelColor, size: 18),
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
                  color: c.jade.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonPrimaryHorizontal,
          vertical: AppSpacing.buttonPrimaryVertical,
        ),
        child: child,
      ),
    );

    // ★ v2.10.3 竖线坍塌第 5 次修复（防御层）：
    // v2.10.1 仅防护 "loose + unbounded" 场景，未防护 "Expanded 给出 tight width < 88"
    // 的矛盾约束场景：ConstrainedBox.enforce(tight(W<88)) 产出 tight(88) 给 child，
    // 但 ConstrainedBox.size 被 parent maxWidth=W<88 clamp 回 W（甚至 0），
    // 造成 size=0 / child=88 的撕裂，release 模式渲染降级为竖线。
    // 防御：LayoutBuilder 检测 tight(maxWidth<88) 矛盾时，放弃 minWidth:88 强制，
    // 直接按可用宽度渲染 box（文字可能裁剪，但按钮本体可见可点击）。
    // 仅在矛盾约束触发，其他 14 个调用点（tight≥88 / loose / unbounded）行为不变。
    // 详见 docs/频发BUG/GoldButton竖线坍塌.md
    final expandedBox = LayoutBuilder(
      builder: (context, constraints) {
        // 矛盾约束判断：tight + maxWidth<88
        final isContradiction =
            constraints.maxWidth.isFinite &&
            constraints.maxWidth < 88 &&
            constraints.minWidth == constraints.maxWidth;
        if (isContradiction) {
          // 降级：放弃 minWidth 兜底，按父级可用宽度渲染，避免竖线坍塌
          return box;
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 88),
          child: box,
        );
      },
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
                child: expandedBox,
              );
            },
          )
        : expandedBox;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        if (!enabled || !animEnabled || widget.onPressed == null) return;
        setState(() => _down = true);
        _press.forward();
      },
      onPointerUp: (_) {
        if (!animEnabled) return;
        setState(() => _down = false);
        _press.reverse();
      },
      onPointerCancel: (_) {
        if (!animEnabled) return;
        setState(() => _down = false);
        _press.reverse();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: enabled ? widget.onPressed : null,
        child: inner,
      ),
    );
  }
}
