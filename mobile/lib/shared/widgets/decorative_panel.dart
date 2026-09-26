// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shared surface panel with a restrained copper outline.
class DecorativePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const DecorativePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.large),
  });

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppSurfaceStyles.panel(c),
      padding: padding,
      child: child,
    );
  }
}
