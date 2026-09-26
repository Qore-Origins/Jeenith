// Copyright (c) 2026 Qore
import 'package:flutter_test/flutter_test.dart';
import 'package:jeenith/core/ai/ai_case_launch_context.dart';
import 'package:jeenith/core/history/history_store.dart';

void main() {
  group('AiCaseLaunchContext', () {
    test('preserves the saved history entry fields and id', () {
      final entry = HistoryEntry(
        id: 'history-1',
        techId: 'zhouyi',
        techName: '周易',
        time: DateTime.utc(2026, 9, 26),
        summary: '乾为天',
        detail: '卦象与爻辞详情',
        note: '当时的备注',
      );

      final context = AiCaseLaunchContext.fromHistoryEntry(entry);

      expect(context.historyEntryId, 'history-1');
      expect(context.techId, 'zhouyi');
      expect(context.techName, '周易');
      expect(context.summary, '乾为天');
      expect(context.detail, '卦象与爻辞详情');
      expect(context.time, DateTime.utc(2026, 9, 26));
      expect(context.note, '当时的备注');
    });

    test('allows transient results without pretending they are saved history', () {
      final context = AiCaseLaunchContext(
        techId: 'luopan',
        techName: '风水罗盘',
        summary: '当前朝向',
        detail: '实时方位读数',
        time: DateTime.utc(2026, 9, 26),
      );

      expect(context.historyEntryId, isNull);
      expect(context.note, isNull);
      expect(context.detail, '实时方位读数');
    });
  });
}
