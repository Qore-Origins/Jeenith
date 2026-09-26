// Copyright (c) 2026 Qore
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/glm_client.dart';
import '../../../core/ai/ai_request_context.dart';
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

  const JiekuaPage({super.key, this.initialEntry});

  @override
  ConsumerState<JiekuaPage> createState() => _JiekuaPageState();
}

class _JiekuaPageState extends ConsumerState<JiekuaPage> {
  final _input = TextEditingController();
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final _scrollCtrl = ScrollController();
  JiekuaSession? _session;
  HistoryEntry? _picked;
  List<JiekuaMessage> _bubbles = const [];
  bool _loading = false;
  String? _error;
  String? _failedQuestion;
  DateTime? _failedMessageTime;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialEntry;
  }

  @override
  void didUpdateWidget(covariant JiekuaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.initialEntry, widget.initialEntry)) return;
    setState(() {
      _session = null;
      _picked = widget.initialEntry;
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
      setState(() => _picked = picked);
      return;
    }
    final updated = current.copyWith(
      techName: picked.techName,
      summary: picked.summary,
      hexuanText: picked.detail,
      updatedAt: DateTime.now(),
    );
    try {
      await JiekuaStore.upsert(updated);
    } catch (_) {
      if (mounted) _toast('关联结果保存失败，请稍后重试。');
      return;
    }
    if (!mounted) return;
    setState(() => _session = updated);
  }

  void _newSession() {
    setState(() {
      _session = null;
      _picked = null;
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
      _bubbles = List.of(s.messages);
      _listKey = GlobalKey<AnimatedListState>();
      _error = null;
      _failedQuestion = null;
      _failedMessageTime = null;
      _input.clear();
    });
    _scrollToBottom(jump: true);
  }

  Future<void> _showHistory() async {
    final list = await JiekuaStore.load();
    if (!mounted) return;
    final c = AppClr.of(context);
    final gradeBad = c.resolve(AppColors.gradeBad, AppColorsLight.gradeBad);
    await showDialog(
      context: context,
      builder: (_) => ThemedDialog(
        title: '解卦历史',
        actions: [
          _dialogAction(
            c,
            '关闭',
            c.textSubtitle,
            () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ],
        child: list.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    '暂无解卦历史',
                    style: TextStyle(color: c.textHint, fontSize: 13),
                  ),
                ),
              )
            : Column(
                children: [
                  for (final s in list)
                    _selectItem(
                      c,
                      title: '${s.techName} · ${s.summary}',
                      subtitle:
                          '${s.messages.length} 条对话 · ${s.updatedAt.toString().substring(0, 16)}',
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        _loadSession(s);
                      },
                      trailing: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          await JiekuaStore.remove(s.id);
                          if (!mounted) return;
                          Navigator.of(context, rootNavigator: true).pop();
                          _showHistory();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.delete_outline,
                            color: gradeBad,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
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
    final session = _session ?? _newSessionForQuestion();
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

  JiekuaSession _newSessionForQuestion() {
    final picked = _picked;
    return JiekuaSession(
      id: JiekuaStore.generateId(),
      techName: picked?.techName ?? '自由问答',
      summary: picked?.summary ?? '新问题',
      hexuanText: picked?.detail ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notes: picked?.note ?? '',
      messages: const [],
    );
  }

  String? _selectedResultContext() {
    final session = _session;
    if (session != null && session.hexuanText.trim().isNotEmpty) {
      return '术数：${session.techName}\n结果摘要：${session.summary}\n\n${session.hexuanText}';
    }
    final entry = _picked;
    if (entry == null) return null;
    return '术数：${entry.techName}\n结果摘要：${entry.summary}\n'
        '计算时间：${entry.time.toString().substring(0, 19)}\n\n${entry.detail}';
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
            const Text('解卦', style: TextStyle(fontSize: 18)),
            Text(
              'AI 问题梳理与术数解读',
              style: TextStyle(
                fontSize: 10,
                color: c.textSubtitle,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          _appBarAction(c, Icons.sticky_note_2_outlined, '本地笔记', _editNotes),
          _appBarAction(c, Icons.history, '解卦历史', _showHistory),
          _appBarAction(c, Icons.add_comment_outlined, '新会话', _newSession),
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
    final resultTitle = _session?.hexuanText.trim().isNotEmpty == true
        ? '${_session!.techName} · ${_session!.summary}'
        : _picked == null
        ? null
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
        borderRadius: BorderRadius.circular(22),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '本地内容默认不发送。每次提问前都可以重新选择。',
              style: TextStyle(color: c.textMeta, fontSize: 11, height: 1.45),
            ),
            const SizedBox(height: 18),
            _contextRailSection(
              c,
              icon: Icons.auto_awesome_outlined,
              title: '关联计算结果',
              body: resultTitle ?? '尚未关联结果。可以先自由提问，或选择一条历史结果。',
              actionLabel: resultTitle == null ? '选择结果' : '更换结果',
              onAction: _pickHexuan,
            ),
            const SizedBox(height: 12),
            _contextRailSection(
              c,
              icon: Icons.sticky_note_2_outlined,
              title: '本地案例笔记',
              body: note.isEmpty ? '仅保存在此设备' : note,
              actionLabel: note.isEmpty ? '添加笔记' : '编辑笔记',
              onAction: _editNotes,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.jade.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
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
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
      borderRadius: BorderRadius.circular(15),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
          style: TextStyle(color: c.textBody, fontSize: 11, height: 1.5),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: onAction, child: Text(actionLabel)),
        ),
      ],
    ),
  );

  Future<void> _editNotes() async {
    final original = _session;
    final target = original ?? _newSessionForQuestion();
    final controller = TextEditingController(text: target.notes);
    final c = AppClr.of(context);
    final updatedNotes = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.card,
        title: Text('本地案例笔记', style: TextStyle(color: c.textPrimary)),
        content: SizedBox(
          width: 460,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 4,
            maxLines: 10,
            maxLength: 4000,
            decoration: const InputDecoration(
              hintText: '记录你自己的观察、背景或后续想法…',
              alignLabelWithHint: true,
            ),
            style: TextStyle(color: c.textPrimary, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('保存到本地'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (updatedNotes == null || !mounted) return;
    final updated = target.copyWith(
      notes: updatedNotes.trim(),
      updatedAt: DateTime.now(),
    );
    try {
      await JiekuaStore.upsert(updated);
      if (!mounted) return;
      setState(() {
        _session = updated;
        _picked = null;
      });
    } catch (_) {
      if (mounted) _toast('笔记保存失败，请稍后重试。');
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.goldBorder.withValues(alpha: 0.4)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: c.textMeta, fontSize: 11),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
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
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
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
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '也可以关联历史计算结果进行解读',
                              style: TextStyle(color: c.textMeta, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '关联结果',
                        style: TextStyle(
                          color: c.jade,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
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
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.forum_outlined, color: c.jade, size: 25),
                ),
                const SizedBox(height: 16),
                Text(
                  '从一个问题开始',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: isDesktop ? 20 : 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '可以先梳理问题，也可以请求推荐合适的术数方法。每次发送前，你都能检查并选择要提供给 AI 的本地资料。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.textMeta,
                    fontSize: 12,
                    height: 1.65,
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
    labelStyle: TextStyle(color: c.textBody, fontSize: 11),
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
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
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
                        fontSize: 13,
                        height: 1.5,
                      ),
                    )
                  : MarkdownBody(
                      data: m.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: c.textBody,
                          fontSize: 13,
                          height: 1.65,
                        ),
                        h2: TextStyle(
                          color: c.goldBright,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: TextStyle(
                          color: c.goldBright,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        strong: TextStyle(
                          color: c.goldBright,
                          fontWeight: FontWeight.bold,
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
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: c.fireGlow.withValues(alpha: 0.5)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            _error!,
            style: TextStyle(color: c.fireGlow, fontSize: 12, height: 1.5),
          ),
        ),
        if (_failedQuestion != null && _input.text.trim() == _failedQuestion)
          TextButton.icon(
            onPressed: _loading ? null : () => _send(retry: true),
            icon: const Icon(Icons.refresh, size: 15),
            label: const Text('重新确认并重试'),
            style: TextButton.styleFrom(
              foregroundColor: c.goldBright,
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
        Text('解读中…', style: TextStyle(color: c.textSubtitle, fontSize: 12)),
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
              style: TextStyle(color: cc.textPrimary, fontSize: 13),
              cursorColor: cc.jade,
              decoration: InputDecoration(
                isDense: true,
                hintText: '描述你想梳理的问题或继续追问…',
                hintStyle: TextStyle(color: cc.textHint, fontSize: 13),
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
              style: FilledButton.styleFrom(
                backgroundColor: cc.jade,
                foregroundColor: Colors.white,
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
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: c.fireGlow, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'AI 生成未必全对，理性看待。',
            style: TextStyle(color: c.fireGlow, fontSize: 10),
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
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: c.fireGlow.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        Icon(Icons.key, color: c.fireGlow, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '未配置 GLM API key，请到设置页「AI 解卦」填写。',
            style: TextStyle(color: c.textBody, fontSize: 12),
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
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
