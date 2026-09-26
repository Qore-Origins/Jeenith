// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jeenith/core/ai/ai_case_launch_context.dart';
import 'package:jeenith/core/ai/jiekua_store.dart';
import 'package:jeenith/core/theme/app_theme.dart';
import 'package:jeenith/features/jiekua/ui/jiekua_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('desktop case rail fits both theme modes', (tester) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    for (final lightTheme in [false, true]) {
      await _pumpWorkspace(tester, width: 1440, lightTheme: lightTheme);
      expect(find.text('案例名称'), findsOneWidget);
      expect(find.text('后续复盘'), findsOneWidget);
      expect(find.text('保存案例'), findsOneWidget);
    }
  });

  testWidgets('saves locally and confirms deletion without an AI request', (
    tester,
  ) async {
    await _pumpWorkspace(
      tester,
      initialContext: AiCaseLaunchContext(
        techId: 'zhouyi',
        techName: '周易',
        summary: '乾为天',
        detail: '本卦与爻辞详情',
        time: DateTime.utc(2026, 9, 26),
        historyEntryId: 'history-42',
      ),
    );
    await tester.enterText(find.byType(TextField).first, '如何调整职业方向？');
    await _openCaseMenu(tester);
    await tester.tap(find.text('保存案例'));
    await tester.pumpAndSettle();

    var cases = await JiekuaStore.load();
    expect(cases, hasLength(1));
    final deletedCaseId = cases.single.id;
    expect(cases.single.initialQuestion, '如何调整职业方向？');
    expect(cases.single.displayTitle, '如何调整职业方向？');
    expect(cases.single.linkedHistoryEntryId, 'history-42');
    expect(cases.single.techName, '周易');
    expect(cases.single.hexuanText, '本卦与爻辞详情');
    expect(find.text('案例已保存在本机。'), findsOneWidget);

    await _openCaseMenu(tester);
    await tester.tap(find.text('案例名称'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '职业抉择案例');
    await tester.tap(find.text('保存到本地'));
    await tester.pumpAndSettle();

    await _openCaseMenu(tester);
    await tester.tap(find.text('后续复盘'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '三个月后方向已经明确。');
    await tester.tap(find.text('保存到本地'));
    await tester.pumpAndSettle();
    cases = await JiekuaStore.load();
    expect(cases.single.title, '职业抉择案例');
    expect(cases.single.reflection, '三个月后方向已经明确。');
    expect(cases.single.reviewedAt, isNotNull);

    await JiekuaStore.upsert(
      _session('case-2', '迁居规划').copyWith(updatedAt: DateTime.utc(2026, 9, 25)),
    );
    await _openCaseMenu(tester);
    await tester.tap(find.text('案例'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('确定删除“职业抉择案例”吗？'), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    cases = await JiekuaStore.load();
    expect(cases.map((session) => session.id), ['case-2']);

    await tester.enterText(find.byType(TextField).first, '新的独立问题');
    await _openCaseMenu(tester);
    await tester.tap(find.text('保存案例'));
    await tester.pumpAndSettle();

    cases = await JiekuaStore.load();
    expect(cases, hasLength(2));
    expect(cases.map((session) => session.id), isNot(contains(deletedCaseId)));
  });
}

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  AiCaseLaunchContext? initialContext,
  double width = 800,
  bool lightTheme = false,
}) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ThemeAnimScope(
      t: lightTheme ? 1 : 0,
      child: ProviderScope(
        child: MaterialApp(
          theme: appTheme(isLight: lightTheme),
          home: JiekuaPage(initialContext: initialContext),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openCaseMenu(WidgetTester tester) async {
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();
}

JiekuaSession _session(String id, String title) => JiekuaSession(
  id: id,
  techName: '周易',
  summary: title,
  hexuanText: '卦象内容',
  title: title,
  createdAt: DateTime.utc(2026, 9, 26),
  updatedAt: DateTime.utc(2026, 9, 26),
  messages: const [],
);
