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
      expect(session.toJson(), containsPair('title', isNull));
      expect(session.toJson(), containsPair('initialQuestion', isNull));
      expect(session.toJson(), containsPair('linkedHistoryEntryId', isNull));
      expect(session.toJson()['reflection'], isEmpty);
      expect(session.toJson(), containsPair('reviewedAt', isNull));
    });

    test('round-trips case metadata added to an existing session', () {
      final session = JiekuaSession.fromJson({
        'id': 'case-1',
        'techName': '周易',
        'summary': '乾为天',
        'hexuanText': '卦象原文',
        'createdAt': '2026-09-26T00:00:00.000Z',
        'updatedAt': '2026-09-26T00:00:00.000Z',
        'title': '职业选择',
        'initialQuestion': '我该如何选择职业方向？',
        'linkedHistoryEntryId': 'history-17',
        'reflection': '一个月后回看',
        'reviewedAt': '2026-10-26T00:00:00.000Z',
        'messages': const [],
      });
      final decoded = JiekuaSession.fromJson(session.toJson());

      expect(session.toJson(), containsPair('title', '职业选择'));
      expect(session.toJson(), containsPair('initialQuestion', '我该如何选择职业方向？'));
      expect(
        session.toJson(),
        containsPair('linkedHistoryEntryId', 'history-17'),
      );
      expect(session.toJson(), containsPair('reflection', '一个月后回看'));
      expect(
        session.toJson(),
        containsPair('reviewedAt', '2026-10-26T00:00:00.000Z'),
      );
      expect(decoded.title, '职业选择');
      expect(decoded.initialQuestion, '我该如何选择职业方向？');
      expect(decoded.linkedHistoryEntryId, 'history-17');
      expect(decoded.reflection, '一个月后回看');
      expect(decoded.reviewedAt, DateTime.utc(2026, 10, 26));
      expect(decoded.displayTitle, '职业选择');
    });

    test('can clear nullable case metadata explicitly', () {
      final session = JiekuaSession.fromJson({
        'id': 'case-clear',
        'techName': '周易',
        'summary': '乾为天',
        'hexuanText': '卦象原文',
        'createdAt': '2026-09-26T00:00:00.000Z',
        'updatedAt': '2026-09-26T00:00:00.000Z',
        'title': '临时标题',
        'initialQuestion': '临时问题',
        'linkedHistoryEntryId': 'history-18',
        'reviewedAt': '2026-10-26T00:00:00.000Z',
        'messages': const [],
      });

      final cleared = session.copyWith(
        clearTitle: true,
        clearInitialQuestion: true,
        clearLinkedHistoryEntryId: true,
        clearReviewedAt: true,
        reflection: '',
      );

      expect(cleared.title, isNull);
      expect(cleared.initialQuestion, isNull);
      expect(cleared.linkedHistoryEntryId, isNull);
      expect(cleared.reviewedAt, isNull);
      expect(cleared.reflection, isEmpty);
    });

    test(
      'uses question, first user message, then technique summary for title',
      () {
        final base = JiekuaSession(
          id: 'title-fallback',
          techName: '周易',
          summary: '乾为天',
          hexuanText: '',
          createdAt: DateTime.utc(2026, 9, 26),
          updatedAt: DateTime.utc(2026, 9, 26),
          messages: [
            JiekuaMessage(
              role: 'assistant',
              content: '欢迎',
              time: DateTime.utc(2026, 9, 26),
            ),
            JiekuaMessage(
              role: 'user',
              content: '  如何开始？  ',
              time: DateTime.utc(2026, 9, 26),
            ),
          ],
        );

        expect(base.displayTitle, '如何开始？');
        expect(base.copyWith(messages: const []).displayTitle, '周易 · 乾为天');
        expect(base.copyWith(initialQuestion: '最初的问题').displayTitle, '最初的问题');
      },
    );

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
