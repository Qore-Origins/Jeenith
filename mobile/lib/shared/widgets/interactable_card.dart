// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';

import '../../core/config/platform_info.dart';
import '../../core/theme/app_theme.dart';

/// 可交互卡片：可选入场动画 + 按下缩放 / 光晕交互 + 桌面端 hover 反馈。
///
/// - **入场**：传入 [entrance] + [interval] 时按序淡入上浮；都不传则无入场。
/// - **交互（触摸端）**：按下轻微缩放并增强边框对比，松开回弹。
/// - **hover（桌面端）**：鼠标移入轻微上移并增强边框与阴影。
///
/// v2.3.1：新增桌面端 hover 反馈（Phase 5）。
class InteractableCard extends StatefulWidget {
  final Animation<double>? entrance;
  final Interval? interval;
  final Color color;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;
  final Widget child;

  const InteractableCard({
    super.key,
    this.entrance,
    this.interval,
    required this.color,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.card,
    required this.child,
  });

  @override
  State<InteractableCard> createState() => _InteractableCardState();
}

class _InteractableCardState extends State<InteractableCard> {
  bool _pressed = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    // 桌面端 hover 计算的视觉参数
    final isDesktop = PlatformInfo.isDesktop;
    final c = AppClr.of(context);
    final cardColor = c.card;
    final hoverShift = isDesktop && _hover ? -2.0 : 0.0;
    final hoverBorderAlpha = _hover ? 0.48 : (_pressed ? 0.42 : 0.26);
    final hoverBlur = _hover ? 14.0 : (_pressed ? 10.0 : 6.0);
    final hoverSpread = _hover ? 0.0 : (_pressed ? 0.5 : 0.0);
    final hoverShadowAlpha = _hover ? 0.10 : (_pressed ? 0.12 : 0.025);

    // 内层：按下缩放 / 光晕 + 卡片内容（独立 final 变量，避免被入场闭包自引用）。
    final content = AnimatedScale(
      scale: _pressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          if (!mounted) return;
          setState(() => _pressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, hoverShift, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(cardColor, widget.color, 0.07)!, cardColor],
            ),
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: widget.color.withValues(alpha: hoverBorderAlpha),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: hoverShadowAlpha),
                blurRadius: hoverBlur,
                spreadRadius: hoverSpread,
              ),
            ],
          ),
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );

    // 桌面端：包裹 MouseRegion 提供 hover 反馈
    final withHover = isDesktop
        ? MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            cursor: widget.onTap != null
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            child: content,
          )
        : content;

    // 可选叠加入场（淡入上浮）；引用不变的 withHover，杜绝闭包自引用。
    final entrance = widget.entrance;
    final interval = widget.interval;
    if (entrance != null && interval != null) {
      return AnimatedBuilder(
        animation: entrance,
        builder: (context, _) {
          final raw = interval.transform(entrance.value).clamp(0.0, 1.0);
          final t = Curves.easeOutCubic.transform(raw);
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 24),
              child: withHover,
            ),
          );
        },
      );
    }
    return withHover;
  }
}
