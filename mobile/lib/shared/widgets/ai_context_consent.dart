// Copyright (c) 2026 Qore
import 'package:flutter/material.dart';

import '../../core/ai/ai_request_context.dart';
import '../../core/ai/jiekua_store.dart';
import '../../core/layout/app_breakpoints.dart';
import '../../core/profiles/profile_store.dart';
import '../../core/theme/app_theme.dart';

/// Shows the exact optional local context available for one model request.
Future<AiRequestSelection?> showAiContextConsent({
  required BuildContext context,
  required String question,
  String? resultText,
  List<JiekuaMessage> previousMessages = const <JiekuaMessage>[],
  String? caseNote,
  List<Profile> profiles = const <Profile>[],
  String? techniqueCatalog,
}) {
  final isDesktop = AppBreakpoints.isDesktopNavigation(
    MediaQuery.sizeOf(context).width,
  );
  final consentForm = _AiContextConsentForm(
    question: question,
    resultText: resultText,
    previousMessages: previousMessages,
    caseNote: caseNote,
    profiles: profiles,
    techniqueCatalog: techniqueCatalog,
  );

  if (isDesktop) {
    return showDialog<AiRequestSelection>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          child: SizedBox(
            width: 620,
            height: (size.height * 0.82).clamp(420.0, 760.0).toDouble(),
            child: consentForm,
          ),
        );
      },
    );
  }

  return showModalBottomSheet<AiRequestSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.92,
      child: Material(
        color: AppClr.of(sheetContext).bgInner,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: consentForm,
      ),
    ),
  );
}

class _AiContextConsentForm extends StatefulWidget {
  final String question;
  final String? resultText;
  final List<JiekuaMessage> previousMessages;
  final String? caseNote;
  final List<Profile> profiles;
  final String? techniqueCatalog;

  const _AiContextConsentForm({
    required this.question,
    required this.resultText,
    required this.previousMessages,
    required this.caseNote,
    required this.profiles,
    required this.techniqueCatalog,
  });

  @override
  State<_AiContextConsentForm> createState() => _AiContextConsentFormState();
}

class _AiContextConsentFormState extends State<_AiContextConsentForm> {
  bool _includeResult = false;
  bool _includeConversation = false;
  bool _includeCaseNote = false;
  bool _includeTechniqueCatalog = false;
  final Set<String> _profileIds = {};

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    final result = widget.resultText?.trim() ?? '';
    final note = widget.caseNote?.trim() ?? '';
    final catalog = widget.techniqueCatalog?.trim() ?? '';
    final conversation = _conversationPreview(widget.previousMessages);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 16, 8),
          child: Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: c.jade, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '确认本次发送内容',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: '取消发送',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: c.textSubtitle),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '本应用只在这次请求中加入所选内容，不会自动带入后续请求。服务商侧的处理与保存按其服务规则进行；未勾选的本地资料不会加入请求。',
              style: TextStyle(color: c.textMeta, fontSize: 12, height: 1.5),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
            children: [
              _questionCard(c),
              const SizedBox(height: 12),
              if (result.isNotEmpty)
                _choice(
                  c,
                  title: '当前计算结果',
                  subtitle: '将已选中的卦象、命盘或其他术数结果发送给模型',
                  value: _includeResult,
                  preview: result,
                  onChanged: (value) =>
                      setState(() => _includeResult = value ?? false),
                ),
              if (conversation.isNotEmpty)
                _choice(
                  c,
                  title: '本次会话的既有对话',
                  subtitle: '${widget.previousMessages.length} 条本地消息；默认不发送',
                  value: _includeConversation,
                  preview: conversation,
                  onChanged: (value) =>
                      setState(() => _includeConversation = value ?? false),
                ),
              if (note.isNotEmpty)
                _choice(
                  c,
                  title: '本地案例笔记',
                  subtitle: '只发送此案例中保存的笔记',
                  value: _includeCaseNote,
                  preview: note,
                  onChanged: (value) =>
                      setState(() => _includeCaseNote = value ?? false),
                ),
              for (final profile in widget.profiles)
                _choice(
                  c,
                  title: '个人档案：${profile.name}',
                  subtitle:
                      '${profile.birthDisplay} · ${profile.isMale ? '男' : '女'}',
                  value: _profileIds.contains(profile.id),
                  preview: AiRequestContextBuilder.formatProfile(profile),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      _profileIds.add(profile.id);
                    } else {
                      _profileIds.remove(profile.id);
                    }
                  }),
                ),
              if (catalog.isNotEmpty)
                _choice(
                  c,
                  title: '应用内置术数目录',
                  subtitle: '用于请 AI 推荐适合的方法，不包含个人资料',
                  value: _includeTechniqueCatalog,
                  preview: catalog,
                  onChanged: (value) =>
                      setState(() => _includeTechniqueCatalog = value ?? false),
                ),
            ],
          ),
        ),
        _actions(c),
      ],
    );
  }

  Widget _questionCard(AppClr c) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: c.jade.withValues(alpha: 0.34)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note, color: c.jade, size: 18),
            const SizedBox(width: 7),
            Text(
              '本次问题（必发送）',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SelectableText(
          widget.question,
          style: TextStyle(color: c.textBody, fontSize: 13, height: 1.55),
        ),
      ],
    ),
  );

  Widget _choice(
    AppClr c, {
    required String title,
    required String subtitle,
    required bool value,
    required String preview,
    required ValueChanged<bool?> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? c.jade.withValues(alpha: 0.38)
              : c.goldBorder.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: value,
            onChanged: onChanged,
            activeColor: c.jade,
            checkColor: Colors.white,
            contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              title,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                subtitle,
                style: TextStyle(color: c.textMeta, fontSize: 11),
              ),
            ),
          ),
          if (value)
            Padding(
              padding: const EdgeInsets.fromLTRB(54, 0, 12, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.bgInner,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  preview,
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _actions(AppClr c) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(
              AiRequestSelection(
                includeResult: _includeResult,
                includeConversation: _includeConversation,
                includeCaseNote: _includeCaseNote,
                includeTechniqueCatalog: _includeTechniqueCatalog,
                profileIds: _profileIds,
              ),
            ),
            icon: const Icon(Icons.send, size: 17),
            label: const Text('发送所选内容'),
            style: FilledButton.styleFrom(
              backgroundColor: c.jade,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );

  static String _conversationPreview(List<JiekuaMessage> messages) => messages
      .where(
        (message) =>
            (message.role == 'user' || message.role == 'assistant') &&
            message.content.trim().isNotEmpty,
      )
      .map(
        (message) =>
            '${message.role == 'user' ? '你' : 'AI'}：${message.content}',
      )
      .join('\n\n');
}
