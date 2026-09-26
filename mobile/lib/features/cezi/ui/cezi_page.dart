// Copyright (c) 2026 Qore
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animation/reveal/reveal_animation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/config_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/history/history_store.dart';
import '../../../core/history/history_providers.dart';
import '../../../shared/widgets/decorative_panel.dart';
import '../../../shared/widgets/dark_button.dart';
import '../../../shared/widgets/copy_result_button.dart';
import '../../../shared/widgets/share_result_button.dart';
import '../../../shared/widgets/ai_case_launch_button.dart';
import '../../../shared/widgets/gold_button.dart';
import '../algorithm/divine.dart';

class CeziPage extends ConsumerStatefulWidget {
  const CeziPage({super.key});

  @override
  ConsumerState<CeziPage> createState() => _CeziPageState();
}

class _CeziPageState extends ConsumerState<CeziPage> {
  final _ctrl = TextEditingController();
  CeziResult? _last;
  HistoryEntry? _resultHistoryEntry;
  String? _error;
  final GlobalKey _boundaryKey = GlobalKey();
  static final _hanRegex = RegExp(r'^[\u4e00-\u9fa5]$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRestore());
  }

  /// v2.4.3：从历史记录恢复（pendingRestoreProvider），按 extra.char 重建。
  void _maybeRestore() {
    final restore = ref.read(pendingRestoreProvider);
    if (restore == null || restore.techId != 'cezi') return;
    final ch = restore.extra?['char'] as String?;
    ref.read(pendingRestoreProvider.notifier).state = null;
    if (ch == null || ch.isEmpty || !_hanRegex.hasMatch(ch)) return;
    setState(() {
      _ctrl.text = ch;
      _last = divine(ch);
      _resultHistoryEntry = restore;
      _error = null;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDivine() {
    FocusScope.of(context).unfocus();
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = '请输入一个汉字');
      return;
    }
    final ch = raw.isEmpty ? '' : String.fromCharCode(raw.runes.first);
    if (!_hanRegex.hasMatch(ch)) {
      setState(() => _error = '请输入单个汉字（仅支持简繁体汉字）');
      return;
    }
    final result = divine(ch);
    setState(() {
      _last = result;
      _error = null;
    });
    final entry = HistoryEntry(
      id: HistoryStore.generateId(),
      techId: 'cezi',
      techName: '测字',
      time: DateTime.now(),
      summary: '「$ch」${result.strokes}画 · ${result.wuxing.label}',
      detail: _buildCopyText(result),
      extra: {'char': ch},
    );
    setState(() => _resultHistoryEntry = entry);
    unawaited(HistoryStore.add(entry));
  }

  void _onReset() {
    setState(() {
      _last = null;
      _resultHistoryEntry = null;
      _error = null;
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Column(
          children: [
            const Text('测　字', style: TextStyle(fontSize: AppFontSize.title)),
            Text(
              '一 字 一 玄 机',
              style: TextStyle(
                fontSize: AppFontSize.micro,
                color: c.textSubtitle,
                letterSpacing: AppLetterSpacing.decorative,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          DecorativePanel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, color: c.goldBright, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '请输入一个汉字',
                      style: TextStyle(
                        color: c.goldBright,
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: AppFontWeight.bold,
                        letterSpacing: AppLetterSpacing.label,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _ctrl,
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: AppFontSize.display,
                    fontWeight: AppFontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '字',
                    counterText: '',
                  ),
                  onSubmitted: (_) => _onDivine(),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: c.gradeBad,
                        fontSize: AppFontSize.label,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GoldButton(text: '测字', onPressed: _onDivine),
          const SizedBox(height: 8),
          DarkButton(text: '清空', onPressed: _onReset),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CopyResultButton(
                  text: _buildCopyText(_last),
                  enabled: _last != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShareResultButton(
                  boundaryKey: _boundaryKey,
                  enabled: _last != null,
                  fallbackText: _buildCopyText(_last),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_last != null)
            RepaintBoundary(key: _boundaryKey, child: _buildResult(_last!)),
          if (_resultHistoryEntry != null)
            Center(
              child: AiCaseLaunchButton.fromHistoryEntry(_resultHistoryEntry!),
            ),
          const SizedBox(height: 12),
          DecorativePanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '◆ 测字要诀',
                  style: TextStyle(
                    color: c.goldBright,
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: AppFontWeight.bold,
                    letterSpacing: AppLetterSpacing.label,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '1. 凝神静气，默念所问之事。',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                    height: AppLineHeight.reading,
                  ),
                ),
                Text(
                  '2. 心中浮现一个字，输入此字。',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                    height: AppLineHeight.reading,
                  ),
                ),
                Text(
                  '3. 拆字笔画 → 五行属性 → 断语吉凶。',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                    height: AppLineHeight.reading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '注：笔画按传统康熙字典体计；未收录字按 unicode 哈希估算。',
                  style: TextStyle(
                    color: c.textHint,
                    fontSize: AppFontSize.micro,
                    height: AppLineHeight.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(CeziResult r) {
    final wxColor = _colorForWuxing(r.wuxing);
    final c = AppClr.of(context);
    final enabled =
        ref
            .watch(configProvider)
            .valueOrNull
            ?.isAnimationEnabled('cezi', AnimationKind.reveal) ??
        true;
    return DecorativePanel(
      padding: const EdgeInsets.all(16),
      child: RevealAnimation(
        enabled: enabled,
        replayKey: r,
        hero: Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: c.bgMid.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: wxColor.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              r.inputChar,
              style: TextStyle(
                color: c.textHighlight,
                fontSize: AppFontSize.ritualLarge,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ),
        sections: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _attrChip('笔画', '${r.strokes} 画', c.goldBright),
              _attrChip('五行', r.wuxing.label, wxColor),
              _attrChip('性情', r.wuxing.nature, c.textBody),
            ],
          ),
          _sectionLabel('字形拆解'),
          Text(
            r.strokeAnalysis,
            style: TextStyle(
              color: c.textBody,
              fontSize: AppFontSize.bodySmall,
              height: AppLineHeight.reading,
            ),
          ),
          _sectionLabel('断语诗'),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: c.bgMid.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(color: c.goldBorder),
            ),
            child: Text(
              r.poem,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: AppFontSize.body,
                height: AppLineHeight.ritual,
                letterSpacing: AppLetterSpacing.subtle,
              ),
            ),
          ),
          _sectionLabel('解字'),
          Text(
            r.interpretation,
            style: TextStyle(
              color: c.textBody,
              fontSize: AppFontSize.bodySmall,
              height: AppLineHeight.reading,
            ),
          ),
          _sectionLabel('详注'),
          Text(
            r.detail,
            style: TextStyle(
              color: c.textMeta,
              fontSize: AppFontSize.label,
              height: AppLineHeight.reading,
              letterSpacing: AppLetterSpacing.subtle,
            ),
          ),
          Center(
            child: Text(
              '${r.time.toString().substring(0, 19)} 测得',
              style: TextStyle(
                color: c.textHint,
                fontSize: AppFontSize.caption,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attrChip(String label, String value, Color color) {
    final c = AppClr.of(context);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: c.textSubtitle,
            fontSize: AppFontSize.caption,
            letterSpacing: AppLetterSpacing.label,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.bold,
              letterSpacing: AppLetterSpacing.subtle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    final c = AppClr.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 3, height: 14, color: c.gold),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: c.goldBright,
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.bold,
              letterSpacing: AppLetterSpacing.label,
            ),
          ),
        ],
      ),
    );
  }

  /// 生成详细结果文本（供复制）。
  String _buildCopyText(CeziResult? r) {
    if (r == null) return '';
    final sb = StringBuffer('【测字 · 一字一玄机】\n');
    sb.writeln('时间：${r.time.toString().substring(0, 19)}');
    sb.writeln('字：「${r.inputChar}」');
    sb.writeln('笔画：${r.strokes} 画');
    sb.writeln('五行：${r.wuxing.label}（${r.wuxing.nature}）');
    sb.writeln('\n拆解：${r.strokeAnalysis}');
    sb.writeln('\n断语诗：');
    sb.writeln(r.poem);
    sb.writeln('\n解字：${r.interpretation}');
    sb.writeln('详注：${r.detail}');
    sb.writeln('\n—— 志极 Jeenith · 叩问本心 ——');
    return sb.toString();
  }

  Color _colorForWuxing(WuxingAttr w) {
    final c = AppClr.of(context);
    return switch (w) {
      WuxingAttr.metal => c.metal,
      WuxingAttr.wood => c.wood,
      WuxingAttr.water => c.waterDeep,
      WuxingAttr.fire => c.fire,
      WuxingAttr.earth => c.earth,
    };
  }
}
