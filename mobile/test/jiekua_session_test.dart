// Copyright (c) 2026 Qore
import 'package:flutter_test/flutter_test.dart';
import 'package:jeenith/core/ai/jiekua_store.dart';

void main() {
  group('JiekuaSession local notes', () {
    test('reads legacy sessions without a notes field', () {
      final session = JiekuaSession.fromJson({
        'id': 'session-1',
        'techName': '周易',
        'summary': '乾为天',
        'hexuanText': '旧结果',
        'createdAt': '2026-09-26T00:00:00.000Z',
        'updatedAt': '2026-09-26T00:00:00.000Z',
        'messages': const [],
      });

      expect(session.notes, isEmpty);
      expect(session.messages, isEmpty);
    });

    test('persists notes through JSON and copyWith', () {
      final session = JiekuaSession(
        id: 'session-2',
        techName: '自由问答',
        summary: '新问题',
        hexuanText: '',
        createdAt: DateTime.utc(2026, 9, 26),
        updatedAt: DateTime.utc(2026, 9, 26),
        notes: '仅保存在设备上的笔记',
        messages: const [],
      );

      final decoded = JiekuaSession.fromJson(session.toJson());

      expect(session.toJson()['notes'], '仅保存在设备上的笔记');
      expect(decoded.notes, '仅保存在设备上的笔记');
      expect(decoded.copyWith(notes: '更新后的笔记').notes, '更新后的笔记');
    });
  });
}
