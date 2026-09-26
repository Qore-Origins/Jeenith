// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final Color? color;
  const SectionTitle(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    return Text(
      '◆ $text',
      style: typography.sectionTitle.copyWith(
        color: color ?? typography.colors.gold,
      ),
    );
  }
}
