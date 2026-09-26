// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ai/ai_case_launch_context.dart';
import '../../core/history/history_store.dart';
import '../../core/theme/app_theme.dart';

/// Shared themed action that opens AI interpretation with a result payload.
class AiCaseLaunchButton extends StatelessWidget {
  final AiCaseLaunchContext launchContext;

  const AiCaseLaunchButton({super.key, required this.launchContext});

  factory AiCaseLaunchButton.fromHistoryEntry(HistoryEntry entry, {Key? key}) =>
      AiCaseLaunchButton(
        key: key,
        launchContext: AiCaseLaunchContext.fromHistoryEntry(entry),
      );

  @override
  Widget build(BuildContext context) {
    final colors = AppClr.of(context);
    return OutlinedButton.icon(
      onPressed: () => context.go('/jiekua', extra: launchContext),
      icon: const Icon(Icons.auto_awesome_outlined),
      label: const Text('进入 AI 解读'),
      style: AppButtonStyles.outlined(
        foregroundColor: colors.jade,
        borderColor: colors.goldBorder,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonSecondaryHorizontal,
          vertical: AppSpacing.buttonSecondaryVertical,
        ),
      ),
    );
  }
}
