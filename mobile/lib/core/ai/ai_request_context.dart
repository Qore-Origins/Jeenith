// Copyright (c) 2026 Qore
import '../profiles/profile_store.dart';
import 'glm_client.dart';
import 'jiekua_store.dart';

/// The local context the user approved for one request only.
class AiRequestSelection {
  final bool includeResult;
  final bool includeConversation;
  final bool includeCaseNote;
  final bool includeTechniqueCatalog;
  final Set<String> profileIds;

  AiRequestSelection({
    this.includeResult = false,
    this.includeConversation = false,
    this.includeCaseNote = false,
    this.includeTechniqueCatalog = false,
    Iterable<String> profileIds = const <String>[],
  }) : profileIds = Set<String>.unmodifiable(profileIds);
}

/// Builds the exact model messages from the current question and checked items.
class AiRequestContextBuilder {
  AiRequestContextBuilder._();

  static List<GlmMessage> buildMessages({
    required String question,
    required AiRequestSelection selection,
    String? resultText,
    List<JiekuaMessage> previousMessages = const <JiekuaMessage>[],
    String? caseNote,
    List<Profile> profiles = const <Profile>[],
    String? techniqueCatalog,
  }) {
    final messages = <GlmMessage>[];

    if (selection.includeConversation) {
      for (final message in previousMessages) {
        if ((message.role == 'user' || message.role == 'assistant') &&
            message.content.trim().isNotEmpty) {
          messages.add(GlmMessage(message.role, message.content));
        }
      }
    }

    final selectedContext = <String>[];
    final result = resultText?.trim() ?? '';
    if (selection.includeResult && result.isNotEmpty) {
      selectedContext.add('【应用计算结果】\n$result');
    }

    final note = caseNote?.trim() ?? '';
    if (selection.includeCaseNote && note.isNotEmpty) {
      selectedContext.add('【用户选择发送的本地案例笔记】\n$note');
    }

    final selectedProfiles = profiles
        .where((profile) => selection.profileIds.contains(profile.id))
        .toList(growable: false);
    if (selectedProfiles.isNotEmpty) {
      selectedContext.add(
        '【用户选择发送的个人档案】\n${selectedProfiles.map(formatProfile).join('\n\n')}',
      );
    }

    final catalog = techniqueCatalog?.trim() ?? '';
    if (selection.includeTechniqueCatalog && catalog.isNotEmpty) {
      selectedContext.add('【应用内置术数目录】\n$catalog');
    }

    final currentQuestion = question.trim();
    if (currentQuestion.isNotEmpty) {
      final content = selectedContext.isEmpty
          ? currentQuestion
          : '${selectedContext.join('\n\n')}\n\n【当前问题】\n$currentQuestion';
      messages.add(GlmMessage('user', content));
    }

    return List<GlmMessage>.unmodifiable(messages);
  }

  static String formatProfile(Profile profile) {
    final lines = <String>[
      '姓名：${profile.name}',
      '出生信息：${profile.birthDisplay}',
      '性别：${profile.isMale ? '男' : '女'}',
    ];
    final note = profile.note?.trim() ?? '';
    if (note.isNotEmpty) lines.add('个人备注：$note');
    return lines.join('\n');
  }
}
