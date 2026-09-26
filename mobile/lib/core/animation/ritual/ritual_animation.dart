// Copyright (c) 2026 Qore
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../theme/animations.dart';
import '../../theme/app_theme.dart';

/// 仪式动画抽象基类。
///
/// 子类需：
/// 1. 创建自己的 [AnimationController]（vsync: this）
/// 2. 动画播完调用 [complete]
/// 3. 在 build 中调用 [ritualScaffold] 包裹动画内容（自动提供 3s 跳过按钮）
///
/// v2.3.0: 是否进入仪式动画由 [HomePage._onTapTech] 根据
/// `AppConfig.isAnimationEnabled(id)` 在路由层决定，本组件被加载即视为启用。
abstract class RitualAnimation extends ConsumerStatefulWidget {
  final VoidCallback? onCompleted;
  const RitualAnimation({super.key, this.onCompleted});
}

abstract class RitualAnimationState<T extends RitualAnimation>
    extends ConsumerState<T> with TickerProviderStateMixin {
  bool _showSkip = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: AppAnimations.skipButtonDelay), () {
      if (mounted) setState(() => _showSkip = true);
    });
  }

  /// 动画播完或跳过时调用，触发 [onCompleted]。
  void complete() {
    if (mounted) widget.onCompleted?.call();
  }

  /// 跳过动画。
  void skip() => complete();

  /// 用深色背景 + 跳过按钮包裹动画内容。
  Widget ritualScaffold(Widget content) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(child: content),
          if (_showSkip)
            Positioned(
              bottom: 36,
              right: 24,
              child: _SkipButton(onTap: skip),
            ),
        ],
      ),
    );
  }
}

/// 跳过按钮——鎏金描边、半透明背景、淡入出现。
class _SkipButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SkipButton({required this.onTap});

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, child) => Opacity(opacity: _fade.value, child: child),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.dialogLarge),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.38)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '跳过',
                style: TextStyle(
                  color: AppColors.gold.withValues(alpha: 0.82),
                  fontSize: AppFontSize.bodySmall,
                  letterSpacing: AppLetterSpacing.decorative,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_double_arrow_right,
                color: AppColors.gold.withValues(alpha: 0.82),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
