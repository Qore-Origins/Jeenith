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
import '../../../shared/widgets/tech_guide_overlay.dart';
import '../algorithm/divine.dart';
import '../algorithm/shensha.dart';

// -- Shichen constants ---------------------------------------------------

const _shichenLabels = [
  '子时 (23:00-01:00)',
  '丑时 (01:00-03:00)',
  '寅时 (03:00-05:00)',
  '卯时 (05:00-07:00)',
  '辰时 (07:00-09:00)',
  '巳时 (09:00-11:00)',
  '午时 (11:00-13:00)',
  '未时 (13:00-15:00)',
  '申时 (15:00-17:00)',
  '酉时 (17:00-19:00)',
  '戌时 (19:00-21:00)',
  '亥时 (21:00-23:00)',
];

// -- Five-element → color ------------------------------------------------

Color _wuxingColor(String wx, AppClr c) => switch (wx) {
  '木' => c.wood,
  '火' => c.fire,
  '土' => c.earth,
  '金' => c.metal,
  '水' => c.waterDeep,
  _ => c.textBody,
};

// -- Page ----------------------------------------------------------------

class BaziPage extends ConsumerStatefulWidget {
  const BaziPage({super.key});

  @override
  ConsumerState<BaziPage> createState() => _BaziPageState();
}

class _BaziPageState extends ConsumerState<BaziPage> {
  DateTime _birthDate = DateTime(1995, 6, 15);
  int? _hourIndex; // null = unknown
  int _gender = 1; // 1 = male, 0 = female
  BaziResult? _r;
  HistoryEntry? _resultHistoryEntry;
  String? _error;
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRestore();
      _showGuide();
    });
  }

  /// 首次进入显示使用指引（只弹一次）。
  Future<void> _showGuide() =>
      showTechGuideOnce(context, 'bazi', '八字推演 · 使用指引', const [
        GuideStep('生辰输入', '选择公历出生年月日 + 时辰（不知时可留空）+ 性别，排出四柱（年/月/日/时）。'),
        GuideStep('四柱十神', '天干地支 + 纳音五行 + 十神（比/劫/食/伤/财/官/杀/印），日干为命主。'),
        GuideStep('大运', '阳男阴女顺行、阴男阳女逆行，从月柱起每十年一运，看行运五行喜忌。'),
        GuideStep('五行喜用', '日主旺则宜克泄耗、衰则宜生扶，喜用神定一生吉凶方向。'),
      ]);

  /// v2.4.3：从历史记录恢复，按 extra 重建生辰 + 推演。
  void _maybeRestore() {
    final restore = ref.read(pendingRestoreProvider);
    if (restore == null || restore.techId != 'bazi') return;
    final extra = restore.extra;
    ref.read(pendingRestoreProvider.notifier).state = null;
    if (extra == null) return;
    final y = extra['year'] as int?;
    final m = extra['month'] as int?;
    final d = extra['day'] as int?;
    final h = extra['hourIndex'] as int?;
    final g = extra['gender'] as int?;
    if (y == null || m == null || d == null) return;
    setState(() {
      _birthDate = DateTime(y, m, d);
      _hourIndex = h;
      _gender = g ?? 1;
    });
    final result = divine(
      year: y,
      month: m,
      day: d,
      hourIndex: h,
      gender: g ?? 1,
    );
    setState(() {
      _r = result;
      _resultHistoryEntry = restore;
    });
  }

  void _onDivine() {
    FocusScope.of(context).unfocus();
    final y = _birthDate.year;
    final m = _birthDate.month;
    final d = _birthDate.day;

    if (y < 1900 || y > 2100) {
      setState(() => _error = '年份需在 1900–2100 之间');
      return;
    }

    final result = divine(
      year: y,
      month: m,
      day: d,
      hourIndex: _hourIndex,
      gender: _gender,
    );

    setState(() {
      _r = result;
      _error = null;
    });

    final entry = HistoryEntry(
      id: HistoryStore.generateId(),
      techId: 'bazi',
      techName: '八字推演',
      time: DateTime.now(),
      summary: _buildSummary(result),
      detail: _buildCopyText(result),
      extra: {
        'year': y,
        'month': m,
        'day': d,
        'hourIndex': _hourIndex,
        'gender': _gender,
      },
    );
    setState(() => _resultHistoryEntry = entry);
    unawaited(HistoryStore.add(entry));
  }

  void _onReset() {
    setState(() {
      _r = null;
      _resultHistoryEntry = null;
      _error = null;
      _hourIndex = null;
      _gender = 1;
      _birthDate = DateTime(1995, 6, 15);
    });
  }

  Future<void> _pickDate() async {
    final c = AppClr.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
      helpText: '选择阳历生辰',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: c.jade,
              onPrimary: c.onAction,
              surface: c.bgInner,
              onSurface: c.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
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
            const Text('八字推演', style: TextStyle(fontSize: AppFontSize.title)),
            Text(
              '四 柱 命 理',
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
          // -- Input panel --
          DecorativePanel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.cake, color: c.goldBright, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '阳历生辰',
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

                // Date picker row
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: c.bgInner,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      border: Border.all(color: c.goldBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: c.gold, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          '${_birthDate.year}年${_birthDate.month}月${_birthDate.day}日',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: AppFontSize.button,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down, color: c.textHint),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Gender selection
                Text(
                  '性别',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _genderToggle(
                        '男',
                        1,
                        icon: Icons.male,
                        color: c.waterDeepGlow,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _genderToggle(
                        '女',
                        0,
                        icon: Icons.female,
                        color: c.fireGlow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Shichen dropdown
                Text(
                  '时辰（可选）',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                  ),
                ),
                const SizedBox(height: 6),
                _shichenDropdown(),
                const SizedBox(height: 8),

                // Hint text
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(
                      color: c.goldBorder.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: c.gold, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '*若时辰未知，可不填写。系统将自动略过时柱与大运推演。*',
                          style: TextStyle(
                            color: c.textMeta,
                            fontSize: AppFontSize.caption,
                            height: AppLineHeight.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
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
          GoldButton(text: '排盘推演', onPressed: _onDivine),
          const SizedBox(height: 8),
          DarkButton(text: '重置', onPressed: _onReset),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CopyResultButton(
                  text: _buildCopyText(_r),
                  enabled: _r != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShareResultButton(
                  boundaryKey: _boundaryKey,
                  enabled: _r != null,
                  fallbackText: _buildCopyText(_r),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // -- Result --
          if (_r != null)
            RepaintBoundary(key: _boundaryKey, child: _buildResult(_r!)),
          if (_resultHistoryEntry != null)
            Center(
              child: AiCaseLaunchButton.fromHistoryEntry(_resultHistoryEntry!),
            ),
          const SizedBox(height: 12),

          // -- Help panel --
          DecorativePanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '◆ 八字要诀',
                  style: TextStyle(
                    color: c.goldBright,
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: AppFontWeight.bold,
                    letterSpacing: AppLetterSpacing.label,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '1. 输入阳历生辰（年月日），时辰可选。',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                    height: AppLineHeight.reading,
                  ),
                ),
                Text(
                  '2. 年柱以立春为界，月柱以节气为分。',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                    height: AppLineHeight.reading,
                  ),
                ),
                Text(
                  '3. 大运阳男阴女顺排，阴男阳女逆排，每十年一柱。',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                    height: AppLineHeight.reading,
                  ),
                ),
                Text(
                  '4. 神煞查表含天乙贵人、文昌、华盖等八星。',
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                    height: AppLineHeight.reading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '注：命格批断基于五行强弱与十神配置，仅供参考。',
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

  // -- Input widgets ------------------------------------------------------

  Widget _genderToggle(
    String label,
    int value, {
    required IconData icon,
    required Color color,
  }) {
    final selected = _gender == value;
    final c = AppClr.of(context);
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : c.bgInner,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.6) : c.goldBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : c.textHint, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : c.textBody,
                fontSize: AppFontSize.body,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shichenDropdown() {
    final c = AppClr.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.bgInner,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: c.goldBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _hourIndex,
          isExpanded: true,
          hint: Text(
            '未知（跳过时柱）',
            style: TextStyle(
              color: c.textHint,
              fontSize: AppFontSize.bodySmall,
            ),
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                '未知（跳过时柱）',
                style: TextStyle(
                  color: c.textHint,
                  fontSize: AppFontSize.bodySmall,
                ),
              ),
            ),
            for (var i = 0; i < _shichenLabels.length; i++)
              DropdownMenuItem<int?>(
                value: i,
                child: Text(
                  _shichenLabels[i],
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: AppFontSize.bodySmall,
                  ),
                ),
              ),
          ],
          onChanged: (v) => setState(() => _hourIndex = v),
          dropdownColor: c.bgInner,
          icon: Icon(Icons.arrow_drop_down, color: c.gold),
        ),
      ),
    );
  }

  // -- Result widgets -----------------------------------------------------

  Widget _buildResult(BaziResult r) {
    final c = AppClr.of(context);
    final enabled =
        ref
            .watch(configProvider)
            .valueOrNull
            ?.isAnimationEnabled('bazi', AnimationKind.reveal) ??
        true;
    return RevealAnimation(
      enabled: enabled,
      replayKey: r,
      hero: _buildHeader(r),
      sections: [
        _buildPillars(r),
        if (r.hasTime) _buildDaYun(r) else _buildNoTimeWarning(),
        _buildLiuNian(r),
        _buildShenShas(r),
        _buildMingGe(r),
        _buildWuxingAnalysis(r),
        _buildJieShu(r),
        Center(
          child: Text(
            '${r.divineTime.toString().substring(0, 19)} 推演',
            style: TextStyle(color: c.textHint, fontSize: AppFontSize.caption),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BaziResult r) {
    final c = AppClr.of(context);
    return DecorativePanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: c.goldBright, size: 16),
              const SizedBox(width: 6),
              Text(
                '${r.genderLabel}命 · ${r.solarDisplay}',
                style: TextStyle(
                  color: c.goldBright,
                  fontSize: AppFontSize.body,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            r.lunarDisplay,
            style: TextStyle(
              color: c.textBody,
              fontSize: AppFontSize.bodySmall,
            ),
          ),
          if (r.startYunDisplay != null) ...[
            const SizedBox(height: 4),
            Text(
              '${r.yunForward ? "顺" : "逆"}排 · ${r.startYunDisplay}',
              style: TextStyle(
                color: c.textMeta,
                fontSize: AppFontSize.caption,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPillars(BaziResult r) {
    final c = AppClr.of(context);
    return DecorativePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('四柱'),
          const SizedBox(height: 8),
          // Pillar header row
          Row(
            children: [
              for (final p in r.pillars)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    child: Text(
                      p.label,
                      style: TextStyle(
                        color: p.label == '日柱' ? c.goldBright : c.textSubtitle,
                        fontSize: AppFontSize.label,
                        fontWeight: AppFontWeight.bold,
                        letterSpacing: AppLetterSpacing.subtle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Ganzhi display
          const SizedBox(height: 4),
          Row(
            children: [
              for (final p in r.pillars)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: p.label == '日柱'
                          ? c.gold.withValues(alpha: 0.1)
                          : c.bgMid.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      border: Border.all(color: c.goldBorder),
                    ),
                    child: Column(
                      children: [
                        Text(
                          p.gan,
                          style: TextStyle(
                            color: _wuxingColor(ganWuxing[p.gan]!, c),
                            fontSize: AppFontSize.metric,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        Text(
                          p.zhi,
                          style: TextStyle(
                            color: _wuxingColor(zhiWuxing[p.zhi] ?? '土', c),
                            fontSize: AppFontSize.metric,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Detail rows
          _pillarDetailRow('纳音', r.pillars.map((p) => p.nayin).toList()),
          _pillarDetailRow('十神', r.pillars.map((p) => p.shishenGan).toList()),
          _pillarDetailRow(
            '藏干',
            r.pillars.map((p) => p.hideGan.join()).toList(),
          ),
          _pillarDetailRow('地势', r.pillars.map((p) => p.dishi).toList()),
        ],
      ),
    );
  }

  Widget _pillarDetailRow(String label, List<String> values) {
    final c = AppClr.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: TextStyle(
                color: c.textSubtitle,
                fontSize: AppFontSize.caption,
              ),
            ),
          ),
          for (final v in values)
            Expanded(
              child: Text(
                v,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.textBody,
                  fontSize: AppFontSize.caption,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoTimeWarning() {
    final c = AppClr.of(context);
    return DecorativePanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: c.gradeRough, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '未输入时辰，将略过时柱与大运推演。',
              style: TextStyle(color: c.textBody, fontSize: AppFontSize.label),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaYun(BaziResult r) {
    final c = AppClr.of(context);
    return DecorativePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('大运'),
          const SizedBox(height: 8),
          for (final dy in r.daYuns)
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: dy.isCurrent
                    ? c.gold.withValues(alpha: 0.12)
                    : c.bgMid.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border.all(color: c.goldBorder),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      dy.ganZhi,
                      style: TextStyle(
                        color: dy.isCurrent ? c.goldBright : c.textPrimary,
                        fontSize: AppFontSize.button,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${dy.startAge}-${dy.endAge}岁 · ${dy.startYear}-${dy.endYear}年',
                      style: TextStyle(
                        color: c.textBody,
                        fontSize: AppFontSize.caption,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _wuxingColor(
                        ganWuxing[dy.ganZhi[0]]!,
                        c,
                      ).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(
                        AppRadius.compactRound,
                      ),
                    ),
                    child: Text(
                      dy.shishenGan,
                      style: TextStyle(
                        color: _wuxingColor(ganWuxing[dy.ganZhi[0]]!, c),
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                  if (dy.isCurrent)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '当前',
                        style: TextStyle(
                          color: c.gold,
                          fontSize: AppFontSize.micro,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiuNian(BaziResult r) {
    final ln = r.currentLiuNian;
    final c = AppClr.of(context);
    return DecorativePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('流年'),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                ln.ganZhi,
                style: TextStyle(
                  color: c.goldBright,
                  fontSize: AppFontSize.title,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${ln.year}年 · 虚岁${ln.age}',
                style: TextStyle(
                  color: c.textBody,
                  fontSize: AppFontSize.bodySmall,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _wuxingColor(
                    ganWuxing[ln.ganZhi[0]]!,
                    c,
                  ).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.compactRound),
                ),
                child: Text(
                  ln.shishenGan,
                  style: TextStyle(
                    color: _wuxingColor(ganWuxing[ln.ganZhi[0]]!, c),
                    fontSize: AppFontSize.label,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShenShas(BaziResult r) {
    final c = AppClr.of(context);
    if (r.shenshas.isEmpty) {
      return DecorativePanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('神煞'),
            const SizedBox(height: 6),
            Text(
              '四柱未见显著神煞。',
              style: TextStyle(color: c.textMeta, fontSize: AppFontSize.label),
            ),
          ],
        ),
      );
    }
    return DecorativePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('神煞'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: r.shenshas.map((s) {
              final isAuspicious = !['亡神'].contains(s.name);
              final color = isAuspicious ? c.woodGlow : c.fireGlow;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.name} · ${s.pillarLabel}（${s.branch}）',
                      style: TextStyle(
                        color: color,
                        fontSize: AppFontSize.label,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          for (final s in r.shenshas)
            if (shenshaDescriptions.containsKey(s.name))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${s.name}：${shenshaDescriptions[s.name]}',
                  style: TextStyle(
                    color: c.textMeta,
                    fontSize: AppFontSize.caption,
                    height: AppLineHeight.body,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMingGe(BaziResult r) {
    final c = AppClr.of(context);
    return DecorativePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('命格批断'),
          const SizedBox(height: 6),
          Text(
            r.mingGe,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: AppFontSize.bodySmall,
              height: AppLineHeight.spacious,
              letterSpacing: AppLetterSpacing.tight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWuxingAnalysis(BaziResult r) {
    final c = AppClr.of(context);
    return DecorativePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('五行分析'),
          const SizedBox(height: 8),
          // Distribution bar
          Row(
            children: r.wuxingDistribution.map((e) {
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      e.element,
                      style: TextStyle(
                        color: _wuxingColor(e.element, c),
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      e.score.toStringAsFixed(1),
                      style: TextStyle(
                        color: _wuxingColor(e.element, c),
                        fontSize: AppFontSize.micro,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            r.wuxingAnalysis,
            style: TextStyle(
              color: c.textBody,
              fontSize: AppFontSize.label,
              height: AppLineHeight.spacious,
              letterSpacing: AppLetterSpacing.tight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJieShu(BaziResult r) {
    final c = AppClr.of(context);
    return DecorativePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 14, color: c.fire),
              const SizedBox(width: 6),
              Text(
                '劫数预警',
                style: TextStyle(
                  color: c.fireGlow,
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold,
                  letterSpacing: AppLetterSpacing.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            r.jieShu,
            style: TextStyle(
              color: c.textBody,
              fontSize: AppFontSize.label,
              height: AppLineHeight.spacious,
              letterSpacing: AppLetterSpacing.tight,
            ),
          ),
        ],
      ),
    );
  }

  // -- Helpers ------------------------------------------------------------

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

  String _buildSummary(BaziResult r) {
    final gz = r.pillars.map((p) => p.ganZhi).join(' ');
    return '$gz · ${r.genderLabel}命${r.hasTime ? '' : '（无时柱）'}';
  }

  String _buildCopyText(BaziResult? r) {
    if (r == null) return '';
    final sb = StringBuffer('【八字推演 · 四柱命理】\n');
    sb.writeln('时间：${r.divineTime.toString().substring(0, 19)}');
    sb.writeln('生辰：${r.solarDisplay}（${r.lunarDisplay}）');
    sb.writeln('性别：${r.genderLabel}命');
    sb.writeln('\n—— 四柱 ——');
    for (final p in r.pillars) {
      sb.writeln(
        '${p.label}：${p.ganZhi} '
        '（${p.wuxing} · ${p.nayin} · ${p.shishenGan} · ${p.dishi}）'
        '  藏干：${p.hideGan.join()}',
      );
    }
    if (r.startYunDisplay != null) {
      sb.writeln('\n—— 大运（${r.yunForward ? "顺排" : "逆排"}）——');
      sb.writeln(r.startYunDisplay!);
      for (final dy in r.daYuns) {
        sb.writeln(
          '${dy.ganZhi} ${dy.startAge}-${dy.endAge}岁 '
          '${dy.startYear}-${dy.endYear}年 ${dy.shishenGan}'
          '${dy.isCurrent ? " ← 当前" : ""}',
        );
      }
    } else {
      sb.writeln('\n（未输入时辰，略过大运推演）');
    }
    sb.writeln('\n—— 流年 ——');
    sb.writeln(
      '${r.currentLiuNian.year}年 ${r.currentLiuNian.ganZhi} '
      '虚岁${r.currentLiuNian.age} ${r.currentLiuNian.shishenGan}',
    );
    if (r.shenshas.isNotEmpty) {
      sb.writeln('\n—— 神煞 ——');
      for (final s in r.shenshas) {
        sb.writeln('${s.name}（${s.pillarLabel}·${s.branch}）');
      }
    }
    sb.writeln('\n—— 命格批断 ——');
    sb.writeln(r.mingGe);
    sb.writeln('\n—— 五行分析 ——');
    sb.writeln(r.wuxingAnalysis);
    sb.writeln('\n—— 劫数预警 ——');
    sb.writeln(r.jieShu);
    sb.writeln('\n—— 志极 Jeenith · 叩问本心 ——');
    return sb.toString();
  }
}
