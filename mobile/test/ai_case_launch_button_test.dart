// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jeenith/core/ai/ai_case_launch_context.dart';
import 'package:jeenith/core/theme/app_theme.dart';
import 'package:jeenith/shared/widgets/ai_case_launch_button.dart';

void main() {
  testWidgets('routes to AI interpretation with the selected result context', (
    tester,
  ) async {
    final launchContext = AiCaseLaunchContext(
      techId: 'zhouyi',
      techName: '周易',
      summary: '乾为天',
      detail: '卦象详情',
      time: DateTime.utc(2026, 9, 26),
      historyEntryId: 'history-42',
    );
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              Scaffold(body: AiCaseLaunchButton(launchContext: launchContext)),
        ),
        GoRoute(
          path: '/jiekua',
          builder: (_, state) {
            final context = state.extra! as AiCaseLaunchContext;
            return Scaffold(
              body: Text('${context.techName}:${context.historyEntryId}'),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: appTheme(), routerConfig: router),
    );
    await tester.tap(find.text('进入 AI 解读'));
    await tester.pumpAndSettle();

    expect(find.text('周易:history-42'), findsOneWidget);
  });
}
