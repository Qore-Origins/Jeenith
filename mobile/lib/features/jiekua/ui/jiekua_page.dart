// Copyright (c) 2026 Qore
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/glm_client.dart';
import '../../../core/ai/ai_request_context.dart';
import '../../../core/ai/ai_case_launch_context.dart';
import '../../../core/ai/jiekua_store.dart';
import '../../../core/config/config_providers.dart';
import '../../../core/divination/divination_registry.dart';
import '../../../core/history/history_store.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/profiles/profile_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ai_context_consent.dart';
import '../../../shared/widgets/decorative_panel.dart';
import '../../../shared/widgets/divination_loading_indicator.dart';
import '../../../shared/widgets/themed_dialog.dart';

/// 解卦页（v3.1.1 重做：主题化，去除原生 Material）。
///
/// v3.0.0 单次解读；v3.1.0 多轮对话 + MD + 本地历史；v3.1.1 视觉重做。
class JiekuaPage extends ConsumerStatefulWidget {
  final HistoryEntry? initialEntry;
  final AiCaseLaunchContext? initialContext;

  const JiekuaPage({super.key, this.initialEntry, this.initialContext});

  @override
  ConsumerState<JiekuaPage> createState() => _JiekuaPageState();
}

class _JiekuaPageState extends ConsumerState<JiekuaPage> {
  final _input = TextEditingController();
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final _scrollCtrl = ScrollController();
  JiekuaSession? _session;
  HistoryEntry? _picked;
  AiCaseLaunchContext? _launchContext;
  List<JiekuaMessage> _bubbles = const [];
  bool _loading = false;
  String? _error;
  String? _failedQuestion;
  DateTime? _failedMessageTime;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialEntry;
    _launchContext =
        widget.initialContext ??
        (widget.initialEntry == null
            ? null
            : AiCaseLaunchContext.fromHistoryEntry(widget.initialEntry!));
  }

  @override
  void didUpdateWidget(covariant JiekuaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.initialEntry, widget.initialEntry) &&
        identical(oldWidget.initialContext, widget.initialContext)) {
      return;
    }
    setState(() {
      _session = null;
      _picked = widget.initialEntry;
      _launchContext =
          widget.initialContext ??
          (widget.initialEntry == null
              ? null
              : AiCaseLaunchContext.fromHistoryEntry(widget.initialEntry!));
      _bubbles = const [];
      _listKey = GlobalKey<AnimatedListState>();
      _error = null;
      _failedQuestion = null;
      _failedMessageTime = null;
      _input.clear();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickHexuan() async {
    final list = await HistoryStore.load();
    if (!mounted) return;
    if (list.isEmpty) {
      _toast('暂无历史卦象，先去卜算一卦吧');
      return;
    }
    final c = AppClr.of(context);
    final picked = await showDialog<HistoryEntry>(
      context: context,
      builder: (_) => ThemedDialog(
        title: '选择卦象',
        actions: [
          _dialogAction(
            c,
            '取消',
            c.textSubtitle,
            () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ],
        child: Column(
          children: [
            for (final e in list)
              _selectItem(
                c,
                title: '${e.techName} · ${e.summary}',
                subtitle: e.time.toString().substring(0, 19),
                onTap: () => Navigator.of(context, rootNavigator: true).pop(e),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    final current = _session;
    if (current == null) {
      setState(() {
        _picked = picked;
        _launchContext = AiCaseLaunchContext.fromHistoryEntry(picked);
      });
      return;
    }
    final updated = current.copyWith(
      techName: picked.techName,
      summary: picked.summary,
      hexuanText: picked.detail,
      linkedHistoryEntryId: picked.id,
      updatedAt: DateTime.now(),
    );
    try {
      await JiekuaStore.upsert(updated);
    } catch (_) {
      if (mounted) _toast('关联结果保存失败，请稍后重试。');
      return;
    }
    if (!mounted) return;
    setState(() {
      _session = updated;
      _picked = null;
      _launchContext = AiCaseLaunchContext.fromHistoryEntry(picked);
    });
  }

  void _newCase() {
    setState(() {
      _session = null;
      _picked = null;
      _launchContext = null;
      _bubbles = const [];
      _listKey = GlobalKey<AnimatedListState>();
      _error = null;
      _failedQuestion = null;
      _failedMessageTime = null;
      _input.clear();
    });
  }

  void _loadSession(JiekuaSession s) {
    setState(() {
      _session = s;
      _picked = null;
      _launchContext = null;
      _bubbles = List.of(s.messages);
      _listKey = GlobalKey<AnimatedListState>();
      _error = null;
      _failedQuestion = null;
      _failedMessageTime = null;
      _input.clear();
    });
    _scrollToBottom(jump: true);
  }

  Future<void> _showCases() async {
    final list = await JiekuaStore.load();
    if (!mounted) return;
    final c = AppClr.of(context);
    final gradeBad = c.resolve(AppColors.gradeBad, AppColorsLight.gradeBad);
    await showDialog(
      context: context,
      builder: (_) => ThemedDialog(
        title: '案例',
        actions: [
          _dialogAction(c, '新建案例', c.jade, () {
            Navigator.of(context, rootNavigator: true).pop();
            _newCase();
          }),
          _dialogAction(
            c,
            '关闭',
            c.textSubtitle,
            () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ],
        child: list.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
                child: Center(
                  child: Text(
                    '还没有保存的案例。\n从问题或计算结果开始，保存后即可在这里继续。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.textHint,
                      fontSize: AppFontSize.bodySmall,
                    ),
                  ),
                ),
              )
            : Column(
                children: [
                  for (final s in list)
                    _selectItem(
                      c,
                      title: s.displayTitle,
                      subtitle:
                          '${s.techName} · ${s.messages.length} 条对话 · '
                          '${s.updatedAt.toString().substring(0, 16)}',
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        _loadSession(s);
                      },
                      trailing: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _confirmDeleteCase(s),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.small),
                          child: Icon(
                            Icons.delete_outline,
                            color: gradeBad,
                            size: AppFontSize.title,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmDeleteCase(JiekuaSession session) async {
    final c = AppClr.of(context);
    final gradeBad = c.resolve(AppColors.gradeBad, AppColorsLight.gradeBad);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ThemedDialog(
        title: '删除案例',
        actions: [
          _dialogAction(
            c,
            '取消',
            c.textSubtitle,
            () => Navigator.of(context, rootNavigator: true).pop(false),
          ),
          _dialogAction(
            c,
            '删除',
            gradeBad,
            () => Navigator.of(context, rootNavigator: true).pop(true),
          ),
        ],
        child: Text(
          '确定删除“${session.displayTitle}”吗？此操作只会删除本机保存的这个案例。',
          style: TextStyle(
            color: c.textBody,
            fontSize: AppFontSize.bodySmall,
            height: AppLineHeight.body,
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (confirmed != true) return;
    try {
      await JiekuaStore.remove(session.id);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (_session?.id == session.id) _newCase();
      _toast('案例已从本机删除。');
    } catch (_) {
      _toast('删除失败，请稍后重试。');
    }
  }

  void _addBubble(JiekuaMessage m) {
    final listState = _listKey.currentState;
    setState(() => _bubbles = [..._bubbles, m]);
    listState?.insertItem(_bubbles.length - 1);
    _scrollToBottom();
  }

  void _removeBubbleAt(int index) {
    if (index < 0 || index >= _bubbles.length) return;
    final removed = _bubbles[index];
    final listState = _listKey.currentState;
    setState(() {
      _bubbles = List.of(_bubbles)..removeAt(index);
    });
    listState?.removeItem(
      index,
      (context, animation) => _bubble(AppClr.of(context), removed, animation),
      duration: const Duration(milliseconds: 150),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (jump) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      } else {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send({bool retry = false}) async {
    final q = _input.text.trim();
    if (q.isEmpty || _loading) return;
    final key = ref.read(configProvider).valueOrNull?.glmApiKey ?? '';
    if (key.isEmpty) {
      setState(() => _error = '未配置 GLM API key，请到设置页「AI 解卦」填写');
      return;
    }

    final isRetry =
        retry &&
        _failedQuestion == q &&
        _failedMessageTime != null &&
        _bubbles.isNotEmpty &&
        _bubbles.last.role == 'user' &&
        _bubbles.last.content == q &&
        _bubbles.last.time == _failedMessageTime;
    final previousMessages = List<JiekuaMessage>.of(_bubbles);
    if (isRetry && previousMessages.isNotEmpty) {
      final last = previousMessages.last;
      if (last.role == 'user' &&
          last.content == q &&
          last.time == _failedMessageTime) {
        previousMessages.removeLast();
      }
    }

    List<Profile> profiles;
    try {
      profiles = await ProfileStore.load();
    } catch (_) {
      if (mounted) {
        setState(() => _error = '读取本地档案失败，本次没有发送请求。');
      }
      return;
    }
    if (!mounted) return;

    final resultText = _selectedResultContext();
    final caseNote = _session?.notes.trim().isNotEmpty == true
        ? _session!.notes
        : _picked?.note;
    final catalog = ref
        .read(visibleTechsProvider)
        .map(
          (tech) =>
              '${tech.meta.displayName}（${tech.meta.subtitle}）：${tech.meta.description}',
        )
        .join('\n');
    final selection = await showAiContextConsent(
      context: context,
      question: q,
      resultText: resultText,
      previousMessages: previousMessages,
      caseNote: caseNote,
      profiles: profiles,
      techniqueCatalog: catalog,
    );
    if (selection == null || !mounted) return;

    final requestMessages = AiRequestContextBuilder.buildMessages(
      question: q,
      selection: selection,
      resultText: resultText,
      previousMessages: previousMessages,
      caseNote: caseNote,
      profiles: profiles,
      techniqueCatalog: catalog,
    );
    if (requestMessages.isEmpty) {
      setState(() => _error = '没有可发送的内容，请检查问题后重试。');
      return;
    }

    final userMessage = isRetry && _bubbles.isNotEmpty
        ? _bubbles.last
        : JiekuaMessage(role: 'user', content: q, time: DateTime.now());
    var initialQuestion = _session?.initialQuestion;
    if (initialQuestion == null) {
      for (final message in _bubbles) {
        if (message.role == 'user' && message.content.trim().isNotEmpty) {
          initialQuestion = message.content.trim();
          break;
        }
      }
    }
    initialQuestion ??= q;
    final session =
        (_session ?? _newSessionForQuestion(initialQuestion: initialQuestion))
            .copyWith(initialQuestion: initialQuestion);
    final updatedBubbles = isRetry
        ? List.of(_bubbles)
        : [..._bubbles, userMessage];
    final previousListState = _listKey.currentState;
    setState(() {
      _session = session;
      _bubbles = updatedBubbles;
      _input.clear();
      _loading = true;
      _error = null;
      _failedQuestion = null;
      _failedMessageTime = null;
    });
    if (!isRetry && previousListState != null) {
      previousListState.insertItem(updatedBubbles.length - 1);
    }
    _scrollToBottom();

    final aTime = DateTime.now();
    var assistantIndex = -1;
    final buffer = StringBuffer();

    try {
      await JiekuaStore.upsert(
        session.copyWith(
          messages: List.of(_bubbles),
          updatedAt: DateTime.now(),
        ),
      );
      await for (final delta in GlmClient.chatStream(
        messages: requestMessages,
        apiKey: key,
      )) {
        buffer.write(delta);
        if (!mounted) return;
        final assistantMessage = JiekuaMessage(
          role: 'assistant',
          content: buffer.toString(),
          time: aTime,
        );
        if (assistantIndex == -1) {
          _addBubble(assistantMessage);
          assistantIndex = _bubbles.length - 1;
        } else {
          setState(() {
            _bubbles = List.of(_bubbles)..[assistantIndex] = assistantMessage;
          });
        }
      }
      if (!mounted) return;
      if (buffer.isEmpty) {
        throw Exception('AI 暂无回复，请重新授权后重试。');
      }
      final updated = _session!.copyWith(
        messages: List.of(_bubbles),
        updatedAt: DateTime.now(),
      );
      _session = updated;
      await JiekuaStore.upsert(updated);
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      if (assistantIndex >= 0 && assistantIndex < _bubbles.length) {
        _removeBubbleAt(assistantIndex);
      }
      _failedQuestion = q;
      _failedMessageTime = userMessage.time;
      _input.text = q;
      try {
        final failed = _session!.copyWith(
          messages: List.of(_bubbles),
          updatedAt: DateTime.now(),
        );
        _session = failed;
        await JiekuaStore.upsert(failed);
      } catch (_) {
        // The current user message remains visible even if local persistence fails.
      }
      setState(() {
        _error = '解读未完成：${e.toString().replaceFirst('Exception: ', '')}';
        _loading = false;
      });
    }
  }

  JiekuaSession _newSessionForQuestion({String? initialQuestion}) {
    final picked = _picked;
    final launchContext = _launchContext;
    final normalizedQuestion = initialQuestion?.trim();
    return JiekuaSession(
      id: JiekuaStore.generateId(),
      techName: picked?.techName ?? launchContext?.techName ?? '自由问答',
      summary: picked?.summary ?? launchContext?.summary ?? '新问题',
      hexuanText: picked?.detail ?? launchContext?.detail ?? '',
      linkedHistoryEntryId: picked?.id ?? launchContext?.historyEntryId,
      initialQuestion: normalizedQuestion == null || normalizedQuestion.isEmpty
          ? null
          : normalizedQuestion,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notes: picked?.note ?? launchContext?.note ?? '',
      messages: const [],
    );
  }

  String? _selectedResultContext() {
    final session = _session;
    if (session != null && session.hexuanText.trim().isNotEmpty) {
      return '术数：${session.techName}\n结果摘要：${session.summary}\n\n${session.hexuanText}';
    }
    final entry = _picked;
    if (entry != null) {
      return '术数：${entry.techName}\n结果摘要：${entry.summary}\n'
          '计算时间：${entry.time.toString().substring(0, 19)}\n\n${entry.detail}';
    }
    final launchContext = _launchContext;
    if (launchContext == null) return null;
    return '术数：${launchContext.techName}\n结果摘要：${launchContext.summary}\n'
        '计算时间：${launchContext.time.toString().substring(0, 19)}\n\n'
        '${launchContext.detail}';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktopNavigation(width);
    final isWideWorkspace = AppBreakpoints.hasWideAiWorkspace(width);
    final hasKey =
        (ref.watch(configProvider).valueOrNull?.glmApiKey ?? '').isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: !isDesktop,
        title: Column(
          crossAxisAlignment: isDesktop
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            const Text('解卦', style: TextStyle(fontSize: AppFontSize.title)),
            Text(
              'AI 问题梳理与术数解读',
              style: TextStyle(
                fontSize: AppFontSize.micro,
                color: c.textSubtitle,
                letterSpacing: AppLetterSpacing.subtle,
              ),
            ),
          ],
        ),
        actions: isDesktop
            ? [
                _appBarAction(c, Icons.folder_open_outlined, '案例', _showCases),
                _appBarAction(c, Icons.add_comment_outlined, '新案例', _newCase),
              ]
            : [
                PopupMenuButton<String>(
                  tooltip: '案例操作',
                  onSelected: (action) {
                    switch (action) {
                      case 'cases':
                        _showCases();
                      case 'save':
                        _saveCase();
                      case 'title':
                        _editTitle();
                      case 'notes':
                        _editNotes();
                      case 'reflection':
                        _editReflection();
                      case 'new':
                        _newCase();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'cases', child: Text('案例')),
                    PopupMenuItem(
                      value: 'save',
                      child: Text(_session == null ? '保存案例' : '更新案例'),
                    ),
                    const PopupMenuItem(value: 'title', child: Text('案例名称')),
                    const PopupMenuItem(value: 'notes', child: Text('本地笔记')),
                    const PopupMenuItem(
                      value: 'reflection',
                      child: Text('后续复盘'),
                    ),
                    const PopupMenuItem(value: 'new', child: Text('新案例')),
                  ],
                ),
              ],
      ),
      body: isWideWorkspace
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 24, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _conversationWorkspace(
                      c,
                      isDesktop: true,
                      hasKey: hasKey,
                    ),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(width: 286, child: _desktopContextRail(c)),
                ],
              ),
            )
          : _conversationWorkspace(c, isDesktop: isDesktop, hasKey: hasKey),
    );
  }

  Widget _conversationWorkspace(
    AppClr c, {
    required bool isDesktop,
    required bool hasKey,
  }) => Column(
    children: [
      _hexuanBar(c, isDesktop: isDesktop),
      if (!hasKey) _noKeyHint(c),
      Expanded(child: _chatArea(c, isDesktop: isDesktop)),
      if (_error != null) _errorBar(c),
      if (_loading) _loadingBar(c),
      _inputBar(c, isDesktop: isDesktop),
      _disclaimer(c, isDesktop: isDesktop),
    ],
  );

  Widget _desktopContextRail(AppClr c) {
    final caseTitle =
        _session?.displayTitle ??
        (_input.text.trim().isNotEmpty
            ? _input.text.trim()
            : _picked == null
            ? '尚未保存的案例'
            : '${_picked!.techName} · ${_picked!.summary}');
    final resultTitle = _session?.hexuanText.trim().isNotEmpty == true
        ? '${_session!.techName} · ${_session!.summary}'
        : _picked == null
        ? _launchContext == null
              ? null
              : '${_launchContext!.techName} · ${_launchContext!.summary}'
        : '${_picked!.techName} · ${_picked!.summary}';
    final note =
        (_session?.notes.trim().isNotEmpty == true
                ? _session!.notes
                : _picked?.note)
            ?.trim() ??
        '';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: c.bgInner,
        borderRadius: BorderRadius.circular(AppRadius.dialogLarge),
        border: Border.all(color: c.goldBorder.withValues(alpha: 0.55)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: c.jade, size: 19),
                const SizedBox(width: 8),
                Text(
                  '会话资料',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: AppFontSize.button,
                    fontWeight: AppFontWeight.semibold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '本地案例独立保存。每次请求前都可以重新选择发送内容。',
              style: TextStyle(
                color: c.textMeta,
                fontSize: AppFontSize.caption,
                height: AppLineHeight.denseBody,
              ),
            ),
            const SizedBox(height: 18),
            _contextRailSection(
              c,
              icon: Icons.folder_outlined,
              title: '案例名称',
              body: caseTitle,
              actionLabel: '编辑名称',
              onAction: _editTitle,
            ),
            const SizedBox(height: AppSpacing.medium),
            _contextRailSection(
              c,
              icon: Icons.auto_awesome_outlined,
              title: '关联计算结果',
              body: resultTitle ?? '尚未关联结果。可以先自由提问，或选择一条历史结果。',
              actionLabel: resultTitle == null ? '选择结果' : '更换结果',
              onAction: _pickHexuan,
            ),
            const SizedBox(height: AppSpacing.medium),
            _contextRailSection(
              c,
              icon: Icons.sticky_note_2_outlined,
              title: '本地案例笔记',
              body: note.isEmpty ? '仅保存在此设备' : note,
              actionLabel: note.isEmpty ? '添加笔记' : '编辑笔记',
              onAction: _editNotes,
            ),
            const SizedBox(height: AppSpacing.medium),
            _contextRailSection(
              c,
              icon: Icons.event_note_outlined,
              title: '后续复盘',
              body: _session?.reflection.trim().isNotEmpty == true
                  ? _session!.reflection
                  : '记录事情后续如何发展，留待以后回看。',
              actionLabel: _session?.reflection.trim().isNotEmpty == true
                  ? '编辑复盘'
                  : '添加复盘',
              onAction: _editReflection,
            ),
            const SizedBox(height: AppSpacing.large),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.jade.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.panelCompact),
                border: Border.all(color: c.jade.withValues(alpha: 0.22)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, color: c.jade, size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '发送前会展示本次问题与可选资料。勾选项仅用于当前请求。',
                      style: TextStyle(
                        color: c.textBody,
                        fontSize: AppFontSize.caption,
                        height: AppLineHeight.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _saveCase,
                icon: const Icon(Icons.save_outlined),
                label: Text(_session == null ? '保存案例' : '更新案例'),
                style: AppButtonStyles.filled(
                  backgroundColor: c.jade,
                  foregroundColor: c.onAction,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.explore_outlined, size: 17),
                label: const Text('去卜算'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contextRailSection(
    AppClr c, {
    required IconData icon,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(AppRadius.bubble),
      border: Border.all(color: c.goldBorder.withValues(alpha: 0.6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: c.gold, size: 17),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: AppFontSize.label,
                  fontWeight: AppFontWeight.semibold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          body,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: c.textBody,
            fontSize: AppFontSize.caption,
            height: AppLineHeight.body,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: onAction, child: Text(actionLabel)),
        ),
      ],
    ),
  );

  bool get _hasCurrentCaseContent {
    if (_session != null || _picked != null || _bubbles.isNotEmpty) return true;
    return _input.text.trim().isNotEmpty;
  }

  JiekuaSession _currentSessionSnapshot() {
    final question = _input.text.trim();
    var initialQuestion = _session?.initialQuestion;
    if (initialQuestion == null) {
      for (final message in _bubbles) {
        if (message.role == 'user' && message.content.trim().isNotEmpty) {
          initialQuestion = message.content.trim();
          break;
        }
      }
    }
    if (initialQuestion == null && question.isNotEmpty) {
      initialQuestion = question;
    }

    var target =
        _session ??
        _newSessionForQuestion(initialQuestion: initialQuestion ?? question);
    target = target.copyWith(
      messages: List.of(_bubbles),
      updatedAt: DateTime.now(),
    );
    if (initialQuestion != null) {
      target = target.copyWith(initialQuestion: initialQuestion);
    }
    final picked = _picked;
    if (picked != null) {
      target = target.copyWith(
        techName: picked.techName,
        summary: picked.summary,
        hexuanText: picked.detail,
      );
      if (target.notes.isEmpty && picked.note != null) {
        target = target.copyWith(notes: picked.note);
      }
    }
    return target;
  }

  Future<void> _saveCase() async {
    if (_loading) return;
    if (!_hasCurrentCaseContent) {
      _toast('请先输入问题、关联计算结果或开始对话，再保存案例。');
      return;
    }
    final updated = _currentSessionSnapshot();
    try {
      await JiekuaStore.upsert(updated);
      if (!mounted) return;
      setState(() {
        _session = updated;
        _picked = null;
      });
      _toast('案例已保存在本机。');
    } catch (_) {
      if (mounted) _toast('案例保存失败，请稍后重试。');
    }
  }

  Future<void> _editTitle() async {
    if (!_hasCurrentCaseContent) {
      _toast('请先输入问题或关联计算结果，再编辑案例名称。');
      return;
    }
    final target = _currentSessionSnapshot();
    final value = await _editCaseText(
      title: '案例名称',
      initialValue: target.title ?? target.displayTitle,
      hint: '为这段对话起一个便于回看的名称',
      maxLength: 80,
      singleLine: true,
    );
    if (value == null || !mounted) return;
    final normalized = value.trim();
    var updated = target.copyWith(
      updatedAt: DateTime.now(),
      clearTitle: normalized.isEmpty,
    );
    if (normalized.isNotEmpty) updated = updated.copyWith(title: normalized);
    await _persistCaseEdit(updated, failureMessage: '案例名称保存失败，请稍后重试。');
  }

  Future<void> _editNotes() async {
    if (!_hasCurrentCaseContent) {
      _toast('请先输入问题或关联计算结果，再记录案例笔记。');
      return;
    }
    final target = _currentSessionSnapshot();
    final value = await _editCaseText(
      title: '本地案例笔记',
      initialValue: target.notes,
      hint: '记录你自己的观察、背景或后续想法…',
      maxLength: 4000,
    );
    if (value == null || !mounted) return;
    await _persistCaseEdit(
      target.copyWith(notes: value.trim(), updatedAt: DateTime.now()),
      failureMessage: '笔记保存失败，请稍后重试。',
    );
  }

  Future<void> _editReflection() async {
    if (!_hasCurrentCaseContent) {
      _toast('请先输入问题或关联计算结果，再添加后续复盘。');
      return;
    }
    final target = _currentSessionSnapshot();
    final value = await _editCaseText(
      title: '后续复盘',
      initialValue: target.reflection,
      hint: '事情后来如何发展？记录结果与新的认识…',
      maxLength: 4000,
    );
    if (value == null || !mounted) return;
    final normalized = value.trim();
    final updated = target.copyWith(
      reflection: normalized,
      reviewedAt: normalized.isEmpty ? null : DateTime.now(),
      clearReviewedAt: normalized.isEmpty,
      updatedAt: DateTime.now(),
    );
    await _persistCaseEdit(updated, failureMessage: '复盘保存失败，请稍后重试。');
  }

  Future<String?> _editCaseText({
    required String title,
    required String initialValue,
    required String hint,
    required int maxLength,
    bool singleLine = false,
  }) => showDialog<String>(
    context: context,
    builder: (_) => _CaseTextEditorDialog(
      title: title,
      initialValue: initialValue,
      hint: hint,
      maxLength: maxLength,
      singleLine: singleLine,
    ),
  );

  Future<void> _persistCaseEdit(
    JiekuaSession updated, {
    required String failureMessage,
  }) async {
    try {
      await JiekuaStore.upsert(updated);
      if (!mounted) return;
      setState(() {
        _session = updated;
        _picked = null;
      });
      _toast('已保存到本机。');
    } catch (_) {
      if (mounted) _toast(failureMessage);
    }
  }

  /// AppBar 操作（GestureDetector + 金色，无 IconButton）。
  Widget _appBarAction(
    AppClr c,
    IconData icon,
    String tip,
    VoidCallback onTap,
  ) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Tooltip(
      message: tip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Icon(icon, color: c.goldBright, size: 20),
      ),
    ),
  );

  /// 弹窗内选择项（替代 ListTile）。
  Widget _selectItem(
    AppClr c, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.goldBorder.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: AppFontSize.bodySmall,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: c.textMeta,
                      fontSize: AppFontSize.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _dialogAction(
    AppClr c,
    String label,
    Color color,
    VoidCallback onTap,
  ) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppFontSize.body,
          fontWeight: AppFontWeight.bold,
          letterSpacing: AppLetterSpacing.label,
        ),
      ),
    ),
  );

  Widget _hexuanBar(AppClr c, {required bool isDesktop}) {
    final src = _session?.hexuanText.trim().isNotEmpty == true
        ? (_session!.techName, _session!.summary)
        : _picked != null
        ? (_picked!.techName, _picked!.summary)
        : null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: src == null
          ? Container(
              key: const ValueKey('empty'),
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: DecorativePanel(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _pickHexuan,
                  child: Row(
                    children: [
                      Icon(Icons.add_chart, color: c.jade, size: 20),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '先从问题开始',
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: AppFontSize.bodySmall,
                                fontWeight: AppFontWeight.semibold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '也可以关联历史计算结果进行解读',
                              style: TextStyle(
                                color: c.textMeta,
                                fontSize: AppFontSize.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '关联结果',
                        style: TextStyle(
                          color: c.jade,
                          fontSize: AppFontSize.label,
                          fontWeight: AppFontWeight.semibold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.chevron_right,
                        color: c.textSubtitle,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Container(
              key: ValueKey(src.$1 + src.$2),
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: DecorativePanel(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _pickHexuan,
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: c.goldBright, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${src.$1} · ${src.$2}',
                          style: TextStyle(
                            color: c.goldBright,
                            fontSize: AppFontSize.bodySmall,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '更换',
                        style: TextStyle(
                          color: c.gold,
                          fontSize: isDesktop ? 12 : 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _chatArea(AppClr c, {required bool isDesktop}) {
    if (_bubbles.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c.jade.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Icon(Icons.forum_outlined, color: c.jade, size: 25),
                ),
                const SizedBox(height: 16),
                Text(
                  '从一个问题开始',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: isDesktop ? 20 : 17,
                    fontWeight: AppFontWeight.semibold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '可以先梳理问题，也可以请求推荐合适的术数方法。每次发送前，你都能检查并选择要提供给 AI 的本地资料。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.textMeta,
                    fontSize: AppFontSize.label,
                    height: AppLineHeight.relaxedReading,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _suggestionChip(c, '帮我把问题理清楚'),
                    _suggestionChip(c, '推荐合适的术数方法'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return AnimatedList(
      key: _listKey,
      controller: _scrollCtrl,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 12,
        8,
        isDesktop ? 24 : 12,
        16,
      ),
      initialItemCount: _bubbles.length,
      itemBuilder: (context, index, animation) =>
          _bubble(c, _bubbles[index], animation, isDesktop: isDesktop),
    );
  }

  Widget _suggestionChip(AppClr c, String text) => ActionChip(
    label: Text(text),
    avatar: Icon(Icons.auto_awesome_outlined, color: c.jade, size: 15),
    backgroundColor: c.card,
    side: BorderSide(color: c.goldBorder.withValues(alpha: 0.7)),
    labelStyle: TextStyle(color: c.textBody, fontSize: AppFontSize.caption),
    onPressed: () {
      _input.text = text;
      _input.selection = TextSelection.collapsed(offset: text.length);
    },
  );

  Widget _bubble(
    AppClr c,
    JiekuaMessage m,
    Animation<double> anim, {
    bool isDesktop = false,
  }) {
    final isUser = m.role == 'user';
    return SizeTransition(
      sizeFactor: anim,
      axisAlignment: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(isUser ? 0.2 : -0.2, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: anim,
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(vertical: 5),
              constraints: BoxConstraints(
                maxWidth: isDesktop
                    ? 760
                    : MediaQuery.sizeOf(context).width * 0.82,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? c.gold.withValues(alpha: 0.16) : c.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.panelCompact),
                  topRight: const Radius.circular(AppRadius.panelCompact),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
                border: Border.all(
                  color: isUser ? c.gold : c.goldBorder,
                  width: isUser ? 1.1 : 1,
                ),
              ),
              child: isUser
                  ? Text(
                      m.content,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: AppFontSize.bodySmall,
                        height: AppLineHeight.body,
                      ),
                    )
                  : MarkdownBody(
                      data: m.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: c.textBody,
                          fontSize: AppFontSize.bodySmall,
                          height: AppLineHeight.relaxedReading,
                        ),
                        h2: TextStyle(
                          color: c.goldBright,
                          fontSize: AppFontSize.button,
                          fontWeight: AppFontWeight.bold,
                        ),
                        h3: TextStyle(
                          color: c.goldBright,
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                        ),
                        strong: TextStyle(
                          color: c.goldBright,
                          fontWeight: AppFontWeight.bold,
                        ),
                        listBullet: TextStyle(color: c.gold),
                        blockSpacing: 6,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBar(AppClr c) => Container(
    margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: c.fireGlow.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.small),
      border: Border.all(color: c.fireGlow.withValues(alpha: 0.5)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            _error!,
            style: TextStyle(
              color: c.fireGlow,
              fontSize: AppFontSize.label,
              height: AppLineHeight.body,
            ),
          ),
        ),
        if (_failedQuestion != null && _input.text.trim() == _failedQuestion)
          TextButton.icon(
            onPressed: _loading ? null : () => _send(retry: true),
            icon: const Icon(Icons.refresh, size: 15),
            label: const Text('重新确认并重试'),
            style: AppButtonStyles.text(
              foregroundColor: c.jade,
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    ),
  );

  Widget _loadingBar(AppClr c) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: DivinationLoadingIndicator(size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          '解读中…',
          style: TextStyle(color: c.textSubtitle, fontSize: AppFontSize.label),
        ),
      ],
    ),
  );

  Widget _inputBar(AppClr c, {required bool isDesktop}) {
    final cc = AppClr.of(context);
    return Container(
      margin: EdgeInsets.fromLTRB(
        isDesktop ? 22 : 12,
        8,
        isDesktop ? 22 : 12,
        4,
      ),
      padding: EdgeInsets.fromLTRB(14, 6, isDesktop ? 12 : 6, 6),
      decoration: BoxDecoration(
        color: cc.card,
        borderRadius: BorderRadius.circular(isDesktop ? 18 : 26),
        border: Border.all(color: cc.goldBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              style: TextStyle(
                color: cc.textPrimary,
                fontSize: AppFontSize.bodySmall,
              ),
              cursorColor: cc.jade,
              decoration: InputDecoration(
                isDense: true,
                hintText: '描述你想梳理的问题或继续追问…',
                hintStyle: TextStyle(
                  color: cc.textHint,
                  fontSize: AppFontSize.bodySmall,
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 6),
          if (isDesktop)
            FilledButton.icon(
              onPressed: _loading ? null : _send,
              icon: Icon(
                _loading ? Icons.hourglass_top : Icons.arrow_upward,
                size: 17,
              ),
              label: Text(_loading ? '处理中' : '确认发送'),
              style: AppButtonStyles.filled(
                backgroundColor: cc.jade,
                foregroundColor: cc.onAction,
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 14,
                ),
              ),
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _loading ? null : _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _loading
                      ? cc.jade.withValues(alpha: 0.14)
                      : cc.jade.withValues(alpha: 0.24),
                  border: Border.all(
                    color: _loading ? cc.goldBorder : cc.jade,
                    width: 1.1,
                  ),
                ),
                child: Icon(
                  _loading ? Icons.hourglass_top : Icons.send,
                  color: _loading ? cc.textHint : cc.jade,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _disclaimer(AppClr c, {required bool isDesktop}) => Container(
    margin: EdgeInsets.fromLTRB(isDesktop ? 22 : 16, 0, isDesktop ? 22 : 16, 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: c.fireGlow.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.small),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: c.fireGlow, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'AI 生成未必全对，理性看待。',
            style: TextStyle(color: c.fireGlow, fontSize: AppFontSize.micro),
          ),
        ),
      ],
    ),
  );

  Widget _noKeyHint(AppClr c) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: c.fireGlow.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRadius.control),
      border: Border.all(color: c.fireGlow.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        Icon(Icons.key, color: c.fireGlow, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '未配置 GLM API key，请到设置页「AI 解卦」填写。',
            style: TextStyle(color: c.textBody, fontSize: AppFontSize.label),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go('/settings'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '去设置',
              style: TextStyle(
                color: c.gold,
                fontSize: AppFontSize.bodySmall,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CaseTextEditorDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final String hint;
  final int maxLength;
  final bool singleLine;

  const _CaseTextEditorDialog({
    required this.title,
    required this.initialValue,
    required this.hint,
    required this.maxLength,
    required this.singleLine,
  });

  @override
  State<_CaseTextEditorDialog> createState() => _CaseTextEditorDialogState();
}

class _CaseTextEditorDialogState extends State<_CaseTextEditorDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppClr.of(context);
    return ThemedDialog(
      title: widget.title,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: AppButtonStyles.filled(
            backgroundColor: colors.jade,
            foregroundColor: colors.onAction,
          ),
          child: const Text('保存到本地'),
        ),
      ],
      child: TextField(
        controller: _controller,
        autofocus: true,
        minLines: widget.singleLine ? 1 : 4,
        maxLines: widget.singleLine ? 1 : 10,
        maxLength: widget.maxLength,
        textInputAction: widget.singleLine ? TextInputAction.done : null,
        decoration: InputDecoration(
          hintText: widget.hint,
          alignLabelWithHint: !widget.singleLine,
        ),
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: AppFontSize.bodySmall,
          height: AppLineHeight.body,
        ),
      ),
    );
  }
}
