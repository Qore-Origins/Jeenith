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
import '../algorithm/wuge.dart';

class NameTestPage extends ConsumerStatefulWidget {
  const NameTestPage({super.key});

  @override
  ConsumerState<NameTestPage> createState() => _NameTestPageState();
}

class _NameTestPageState extends ConsumerState<NameTestPage> {
  final _ctrl = TextEditingController();
  WugeResult? _last;
  HistoryEntry? _resultHistoryEntry;
  String? _error;
  final GlobalKey _boundaryKey = GlobalKey();
  static final _hanRegex = RegExp(r'^[\u4e00-\u9fa5]{2,4}$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRestore());
  }

  /// v2.4.3：从历史记录恢复，按 extra.name 重建。
  void _maybeRestore() {
    final restore = ref.read(pendingRestoreProvider);
    if (restore == null || restore.techId != 'name_test') return;
    final name = restore.extra?['name'] as String?;
    ref.read(pendingRestoreProvider.notifier).state = null;
    if (name == null || name.isEmpty || !_hanRegex.hasMatch(name)) return;
    setState(() {
      _ctrl.text = name;
      _last = divineName(name);
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
      setState(() => _error = '请输入中文姓名');
      return;
    }
    if (!_hanRegex.hasMatch(raw)) {
      setState(() => _error = '请输入 2-4 个汉字（仅支持简繁体汉字）');
      return;
    }
    final result = divineName(raw);
    setState(() {
      _last = result;
      _error = null;
    });
    final entry = HistoryEntry(
      id: HistoryStore.generateId(),
      techId: 'name_test',
      techName: '测名字',
      time: DateTime.now(),
      summary:
          '「$raw」人格${result.ren.strokes}画·${result.ren.wuxing.label}·${result.ren.fortune.grade}',
      detail: _buildCopyText(result),
      extra: {'name': raw},
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
            const Text('测　名　字', style: TextStyle(fontSize: AppFontSize.title)),
            Text(
              '五 格 剖 象',
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
                    Icon(Icons.badge, color: c.goldBright, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '请输入中文姓名（2-4 字）',
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
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: AppFontSize.heading,
                    fontWeight: AppFontWeight.bold,
                    letterSpacing: AppLetterSpacing.display,
                  ),
                  decoration: const InputDecoration(
                    hintText: '姓名',
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
          GoldButton(text: '测名', onPressed: _onDivine),
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
                  '◆ 测名要诀',
                  style: TextStyle(
                    color: c.goldBright,
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: AppFontWeight.bold,
                    letterSpacing: AppLetterSpacing.label,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '1. 凝神静气，默念姓名主人之事。',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                    height: AppLineHeight.reading,
                  ),
                ),
                Text(
                  '2. 输入完整姓名（2 字为单姓单名，3 字为单姓双名，4 字按复姓双名计）。',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                    height: AppLineHeight.reading,
                  ),
                ),
                Text(
                  '3. 依康熙字典笔画计算五格，定五行吉凶。',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                    height: AppLineHeight.reading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '注：笔画按康熙字典体计；未收录字按 unicode 估算，结果仅供参断。',
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

  Widget _buildResult(WugeResult r) {
    final c = AppClr.of(context);
    final enabled =
        ref
            .watch(configProvider)
            .valueOrNull
            ?.isAnimationEnabled('name_test', AnimationKind.reveal) ??
        true;
    return DecorativePanel(
      padding: const EdgeInsets.all(16),
      child: RevealAnimation(
        enabled: enabled,
        replayKey: r,
        hero: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: c.bgMid.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(color: c.goldBorder, width: 1.5),
            ),
            child: Text(
              r.fullName.split('').join(' '),
              style: TextStyle(
                color: c.textHighlight,
                fontSize: AppFontSize.displaySmall,
                fontWeight: AppFontWeight.bold,
                letterSpacing: AppLetterSpacing.decorative,
              ),
            ),
          ),
        ),
        sections: [
          if (r.hasMissing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.gradeBad.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border.all(color: c.gradeBad.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: c.gradeBad,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '部分汉字笔画数据缺失（${_missingChars(r)}），已按估算推算，结果可能不准。',
                      style: TextStyle(
                        color: c.gradeBad,
                        fontSize: AppFontSize.caption,
                        height: AppLineHeight.compactBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Stroke breakdown
          _sectionLabel('康熙笔画'),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (var i = 0; i < r.chars.length; i++)
                _strokeChip(r.chars[i], r.strokes[i], r.missing[i]),
            ],
          ),
          // Five-grid table
          _sectionLabel('五格数理'),
          _buildGridTable(r),
          // Wuxing distribution
          _sectionLabel('五行分布'),
          _buildWuxingDistribution(r),
          // Verdict
          _sectionLabel('综合批断'),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: c.bgMid.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(color: c.goldBorder),
            ),
            child: Text(
              r.summary,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: AppFontSize.bodySmall,
                height: AppLineHeight.ritual,
                letterSpacing: AppLetterSpacing.tight,
              ),
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

  String _missingChars(WugeResult r) {
    final list = <String>[];
    for (var i = 0; i < r.chars.length; i++) {
      if (r.missing[i]) list.add(r.chars[i]);
    }
    return list.join('、');
  }

  Widget _strokeChip(String ch, int strokes, bool missing) {
    final c = AppClr.of(context);
    final color = missing ? c.gradeBad : c.goldBright;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ch,
            style: TextStyle(
              color: c.textHighlight,
              fontSize: AppFontSize.bodyLarge,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$strokes 画',
            style: TextStyle(
              color: color,
              fontSize: AppFontSize.label,
              fontWeight: AppFontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridTable(WugeResult r) {
    final c = AppClr.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.bgMid.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: c.goldBorder),
      ),
      child: Column(
        children: [
          _gridHeader(),
          _gridRow(r.tian),
          _gridRow(r.ren, highlight: true),
          _gridRow(r.di),
          _gridRow(r.zong),
          _gridRow(r.wai, isLast: true),
        ],
      ),
    );
  }

  Widget _gridHeader() {
    final c = AppClr.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: c.bgInner,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.compactLoose),
          topRight: Radius.circular(AppRadius.compactLoose),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '格',
              style: TextStyle(
                color: c.goldBright,
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '笔画',
              style: TextStyle(
                color: c.goldBright,
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '五行',
              style: TextStyle(
                color: c.goldBright,
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '吉凶',
              style: TextStyle(
                color: c.goldBright,
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridRow(GeResult g, {bool highlight = false, bool isLast = false}) {
    final c = AppClr.of(context);
    final gradeColor = _colorForGrade(g.fortune.grade, c);
    final wxColor = _colorForWuxing(g.wuxing, c);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight
            ? c.gold.withValues(alpha: 0.08)
            : AppColors.transparent,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: c.goldBorder.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              g.name,
              style: TextStyle(
                color: highlight ? c.goldBright : c.textPrimary,
                fontSize: AppFontSize.bodySmall,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${g.strokes}',
              style: TextStyle(
                color: c.textHighlight,
                fontSize: AppFontSize.body,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              g.wuxing.label,
              style: TextStyle(
                color: wxColor,
                fontSize: AppFontSize.bodySmall,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${g.fortune.grade} · ${g.fortune.desc}',
              style: TextStyle(
                color: gradeColor,
                fontSize: AppFontSize.caption,
                height: AppLineHeight.navigation,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWuxingDistribution(WugeResult r) {
    final count = r.wuxingCount;
    const order = [
      Wuxing.metal,
      Wuxing.wood,
      Wuxing.water,
      Wuxing.fire,
      Wuxing.earth,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [for (final w in order) _wuxingChip(w, count[w] ?? 0)],
    );
  }

  Widget _wuxingChip(Wuxing w, int count) {
    final c = AppClr.of(context);
    final color = _colorForWuxing(w, c);
    return Column(
      children: [
        Text(
          w.label,
          style: TextStyle(
            color: color,
            fontSize: AppFontSize.body,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: AppFontSize.body,
              fontWeight: AppFontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          w.nature,
          style: TextStyle(color: c.textMeta, fontSize: AppFontSize.footnote),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    final c = AppClr.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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

  /// Generate the detailed text for copy / share.
  String _buildCopyText(WugeResult? r) {
    if (r == null) return '';
    final sb = StringBuffer('【测名字 · 五格剖象】\n');
    sb.writeln('时间：${r.time.toString().substring(0, 19)}');
    sb.writeln('姓名：「${r.fullName}」');
    sb.writeln(
      '康熙笔画：${r.chars.asMap().entries.map((e) => '${e.value}=${r.strokes[e.key]}画').join(' ')}',
    );
    sb.writeln('姓氏：${r.compoundSurname ? "复姓" : "单姓"}');
    if (r.hasMissing) {
      sb.writeln('（注：${_missingChars(r)} 笔画数据缺失，已估算）');
    }
    sb.writeln('\n—— 五格数理 ——');
    for (final g in [r.tian, r.ren, r.di, r.zong, r.wai]) {
      sb.writeln(
        '${g.name}（${g.role}）：${g.strokes}画 · ${g.wuxing.label} · ${g.fortune.grade} · ${g.fortune.desc}',
      );
    }
    sb.writeln('\n—— 五行分布 ——');
    final count = r.wuxingCount;
    for (final w in [
      Wuxing.metal,
      Wuxing.wood,
      Wuxing.water,
      Wuxing.fire,
      Wuxing.earth,
    ]) {
      sb.writeln('${w.label}（${w.nature}）：${count[w] ?? 0}');
    }
    sb.writeln('\n—— 综合批断 ——');
    sb.writeln(r.summary);
    sb.writeln('\n—— 志极 Jeenith · 叩问本心 ——');
    return sb.toString();
  }

  Color _colorForWuxing(Wuxing w, AppClr c) => switch (w) {
    Wuxing.metal => c.metal,
    Wuxing.wood => c.wood,
    Wuxing.water => c.waterDeep,
    Wuxing.fire => c.fire,
    Wuxing.earth => c.earth,
  };

  Color _colorForGrade(String grade, AppClr c) => switch (grade) {
    '大吉' => c.gradeGreat,
    '吉' => c.gradeGood,
    '平' => c.gradeSteady,
    '凶' => c.gradeRough,
    '大凶' => c.gradeBad,
    _ => c.textBody,
  };
}
