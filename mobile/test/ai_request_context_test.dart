import 'package:flutter_test/flutter_test.dart';
import 'package:jeenith/core/ai/ai_request_context.dart';
import 'package:jeenith/core/ai/jiekua_store.dart';
import 'package:jeenith/core/profiles/profile_store.dart';

void main() {
  group('AiRequestContextBuilder', () {
    test('omits all optional local context unless selected', () {
      final messages = AiRequestContextBuilder.buildMessages(
        question: 'QUESTION_SENTINEL',
        resultText: 'RESULT_SENTINEL',
        previousMessages: [
          JiekuaMessage(
            role: 'user',
            content: 'OLD_USER_SENTINEL',
            time: DateTime.utc(2026),
          ),
          JiekuaMessage(
            role: 'assistant',
            content: 'OLD_ASSISTANT_SENTINEL',
            time: DateTime.utc(2026),
          ),
        ],
        caseNote: 'NOTE_SENTINEL',
        profiles: [_profile('PROFILE_SENTINEL')],
        techniqueCatalog: 'CATALOG_SENTINEL',
        selection: AiRequestSelection(),
      );

      final payload = messages.map((message) => message.toJson()).toString();
      expect(messages, hasLength(1));
      expect(messages.single.role, 'user');
      expect(payload, contains('QUESTION_SENTINEL'));
      expect(payload, isNot(contains('RESULT_SENTINEL')));
      expect(payload, isNot(contains('OLD_USER_SENTINEL')));
      expect(payload, isNot(contains('OLD_ASSISTANT_SENTINEL')));
      expect(payload, isNot(contains('NOTE_SENTINEL')));
      expect(payload, isNot(contains('PROFILE_SENTINEL')));
      expect(payload, isNot(contains('CATALOG_SENTINEL')));
    });

    test('includes only the selected context and preserves chat roles', () {
      final messages = AiRequestContextBuilder.buildMessages(
        question: 'QUESTION_SENTINEL',
        resultText: 'RESULT_SENTINEL',
        previousMessages: [
          JiekuaMessage(
            role: 'user',
            content: 'OLD_USER_SENTINEL',
            time: DateTime.utc(2026),
          ),
          JiekuaMessage(
            role: 'assistant',
            content: 'OLD_ASSISTANT_SENTINEL',
            time: DateTime.utc(2026),
          ),
          JiekuaMessage(
            role: 'system',
            content: 'UNTRUSTED_ROLE_SENTINEL',
            time: DateTime.utc(2026),
          ),
        ],
        caseNote: 'NOTE_SENTINEL',
        profiles: [
          _profile('SELECTED_PROFILE_SENTINEL', id: 'selected-profile'),
          _profile('UNSELECTED_PROFILE_SENTINEL', id: 'other-profile'),
        ],
        techniqueCatalog: 'CATALOG_SENTINEL',
        selection: AiRequestSelection(
          includeResult: true,
          includeConversation: true,
          includeCaseNote: true,
          includeTechniqueCatalog: true,
          profileIds: const {'selected-profile'},
        ),
      );

      final payload = messages.map((message) => message.toJson()).toString();
      expect(messages.map((message) => message.role), [
        'user',
        'assistant',
        'user',
      ]);
      expect(messages.last.content, contains('QUESTION_SENTINEL'));
      expect(payload, contains('RESULT_SENTINEL'));
      expect(payload, contains('OLD_USER_SENTINEL'));
      expect(payload, contains('OLD_ASSISTANT_SENTINEL'));
      expect(payload, contains('NOTE_SENTINEL'));
      expect(payload, contains('SELECTED_PROFILE_SENTINEL'));
      expect(payload, contains('CATALOG_SENTINEL'));
      expect(payload, isNot(contains('UNSELECTED_PROFILE_SENTINEL')));
      expect(payload, isNot(contains('UNTRUSTED_ROLE_SENTINEL')));
    });
  });
}

Profile _profile(String name, {String id = 'profile-1'}) => Profile(
  id: id,
  name: name,
  year: 1990,
  month: 1,
  day: 2,
  hour: 3,
  isMale: true,
  note: 'PRIVATE_PROFILE_NOTE',
  createdAt: DateTime.utc(2026),
);
