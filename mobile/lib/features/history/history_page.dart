// Copyright (c) 2026 Qore
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/history/history_store.dart';
import '../../core/history/history_export.dart';
import '../../core/history/history_providers.dart';
import '../../shared/widgets/decorative_panel.dart';
import '../../shared/widgets/divination_loading_indicator.dart';

/// 历史记录页：列表 + 详情 + 备注 + 删除 + 恢复卦象。
///
/// v2.4.2：全面主题感知（浅色模式适配）。
/// v2.4.3：新增「恢复卦象」按钮（有 extra 可恢复，旧记录置灰）。
/// v2.12.0：搜索 + 按术数筛选 + 批量删除（长按进入多选）。
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  List<HistoryEntry> _list = const [];
  bool _loading = true;
  String _query = '';
  String? _filterTech;
  bool _selectMode = false;
  final Set<String> _selected = {};
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _reload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final list = await HistoryStore.load();
    if (!mounted) return;
    setState(() {
      _list = list;
      _loading = false;
      _selected.removeWhere((id) => !list.any((e) => e.id == id));
    });
  }

  /// 过滤后的列表（搜索词 + 术数筛选）。
  List<HistoryEntry> get _filtered {
    var r = _list;
    if (_filterTech != null) {
      r = r.where((e) => e.techId == _filterTech).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      r = r
          .where(
            (e) =>
                e.summary.toLowerCase().contains(q) ||
                e.techName.toLowerCase().contains(q) ||
                e.detail.toLowerCase().contains(q) ||
                (e.note ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    return r;
  }

  /// 历史中出现过的术数（按首次出现去重保序）。
  List<HistoryEntry> _distinctTechs() {
    final seen = <String>{};
    final out = <HistoryEntry>[];
    for (final e in _list) {
      if (seen.add(e.techId)) out.add(e);
    }
    return out;
  }

  /// 恢复卦象（v2.4.3）。
  void _restore(HistoryEntry e) {
    ref.read(pendingRestoreProvider.notifier).state = e;
    context.go('/tech/${e.techId}');
  }

  /// 复制一条历史记录到剪贴板。
  Future<void> _copyEntry(HistoryEntry e) async {
    final buf = StringBuffer()
      ..writeln('【${e.techName}】${e.summary}')
      ..writeln('时间：${e.time.toString().substring(0, 19)}')
      ..writeln()
      ..writeln(e.detail);
    if (e.note != null && e.note!.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('备注：${e.note}');
    }
    await Clipboard.setData(ClipboardData(text: buf.toString().trimRight()));
    if (!mounted) return;
    final sc = AppClr.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: sc.goldBright, size: 18),
            const SizedBox(width: 8),
            const Expanded(child: Text('已复制到剪贴板')),
          ],
        ),
        backgroundColor: sc.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(color: sc.goldBorder),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openDetail(HistoryEntry e) async {
    final c = AppClr.of(context);
    final gradeBad = c.resolve(AppColors.gradeBad, AppColorsLight.gradeBad);
    final noteCtrl = TextEditingController(text: e.note ?? '');
    ModalRoute<dynamic>? detailRoute;
    bool reloadHistoryAfterClose = false;
    HistoryEntry? entryForAi;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        detailRoute = ModalRoute.of<dynamic>(ctx);
        return AlertDialog(
          backgroundColor: c.card,
          title: Text(
            '${e.techName} · ${e.summary}',
            style: TextStyle(
              color: c.goldBright,
              fontSize: AppFontSize.button,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  '时间：${e.time.toString().substring(0, 19)}',
                  style: TextStyle(
                    color: c.textMeta,
                    fontSize: AppFontSize.label,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.detail,
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: AppFontSize.label,
                    height: AppLineHeight.body,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: '添加备注…',
                    hintStyle: TextStyle(color: c.textHint),
                  ),
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: AppFontSize.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async => _copyEntry(e),
              child: Text('复制', style: TextStyle(color: c.jade)),
            ),
            TextButton(
              onPressed: () async {
                await HistoryStore.remove(e.id);
                if (!ctx.mounted) return;
                reloadHistoryAfterClose = true;
                Navigator.pop(ctx);
              },
              child: Text('删除', style: TextStyle(color: gradeBad)),
            ),
            TextButton(
              onPressed: () async {
                await HistoryStore.updateNote(
                  e.id,
                  noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                );
                if (!ctx.mounted) return;
                reloadHistoryAfterClose = true;
                Navigator.pop(ctx);
              },
              child: Text('保存备注', style: TextStyle(color: c.jade)),
            ),
            TextButton.icon(
              onPressed: () async {
                final note = noteCtrl.text.trim();
                await HistoryStore.updateNote(
                  e.id,
                  note.isEmpty ? null : note,
                );
                if (!mounted || !ctx.mounted) return;
                entryForAi = HistoryEntry(
                  id: e.id,
                  techId: e.techId,
                  techName: e.techName,
                  time: e.time,
                  summary: e.summary,
                  detail: e.detail,
                  note: note.isEmpty ? null : note,
                  extra: e.extra,
                );
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('进入 AI 解读'),
              style: AppButtonStyles.text(foregroundColor: c.jade),
            ),
          ],
        );
      },
    );
    await detailRoute?.completed;
    noteCtrl.dispose();
    if (!mounted) return;
    final analysisEntry = entryForAi;
    if (analysisEntry != null) {
      context.go('/jiekua', extra: analysisEntry);
      return;
    }
    if (reloadHistoryAfterClose) await _reload();
  }

  void _confirmClear() {
    final c = AppClr.of(context);
    final gradeBad = c.resolve(AppColors.gradeBad, AppColorsLight.gradeBad);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text(
          '清空全部历史',
          style: TextStyle(
            color: c.goldBright,
            fontSize: AppFontSize.button,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        content: Text(
          '此操作不可撤销，确定清空所有卜算历史记录？',
          style: TextStyle(color: c.textBody, fontSize: AppFontSize.bodySmall, height: AppLineHeight.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: c.textSubtitle)),
          ),
          TextButton(
            onPressed: () async {
              await HistoryStore.clear();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _reload();
            },
            child: Text('清空', style: TextStyle(color: gradeBad)),
          ),
        ],
      ),
    );
  }

  /// 批量删除选中记录（v2.12.0）。
  void _confirmDeleteSelected() {
    final c = AppClr.of(context);
    final gradeBad = c.resolve(AppColors.gradeBad, AppColorsLight.gradeBad);
    final count = _selected.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text(
          '删除选中记录',
          style: TextStyle(
            color: c.goldBright,
            fontSize: AppFontSize.button,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        content: Text(
          '确定删除选中的 $count 条记录？此操作不可撤销。',
          style: TextStyle(color: c.textBody, fontSize: AppFontSize.bodySmall, height: AppLineHeight.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: c.textSubtitle)),
          ),
          TextButton(
            onPressed: () async {
              final ids = _selected.toList();
              for (final id in ids) {
                await HistoryStore.remove(id);
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              setState(() {
                _selected.clear();
                _selectMode = false;
              });
              _reload();
            },
            child: Text('删除', style: TextStyle(color: gradeBad)),
          ),
        ],
      ),
    );
  }

  void _exitSelectMode() => setState(() {
    _selected.clear();
    _selectMode = false;
  });

  void _toggleSelected(String id) => setState(() {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    if (_selected.isEmpty) _selectMode = false;
  });

  Future<void> _export(String format) async {
    final list = await HistoryStore.load();
    if (!mounted) return;
    if (list.isEmpty) {
      final sc = AppClr.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('暂无历史记录可导出'),
          backgroundColor: sc.card,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    File file;
    switch (format) {
      case 'json':
        file = await HistoryExport.exportJson(list);
        break;
      case 'md':
        file = await HistoryExport.exportMarkdown(list);
        break;
      case 'csv':
        file = await HistoryExport.exportCsv(list);
        break;
      default:
        return;
    }
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppClr.of(context);
    final gradeBad = c.resolve(AppColors.gradeBad, AppColorsLight.gradeBad);
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        leading: _selectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectMode,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
        title: _selectMode
            ? Text('已选 ${_selected.length} 项')
            : const Text('历 史 记 录'),
        actions: _selectMode
            ? [
                IconButton(
                  icon: Icon(
                    filtered.isNotEmpty &&
                            filtered.every((e) => _selected.contains(e.id))
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  tooltip: '全选 / 取消全选',
                  onPressed: filtered.isEmpty
                      ? null
                      : () => setState(() {
                          final all = filtered.every(
                            (e) => _selected.contains(e.id),
                          );
                          if (all) {
                            _selected.removeWhere(
                              (id) => filtered.any((e) => e.id == id),
                            );
                          } else {
                            _selected.addAll(filtered.map((e) => e.id));
                          }
                        }),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: gradeBad),
                  tooltip: '删除选中',
                  onPressed: _selected.isEmpty ? null : _confirmDeleteSelected,
                ),
              ]
            : [
                if (_list.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.ios_share, color: c.gold),
                    tooltip: '导出历史',
                    onSelected: _export,
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'json', child: Text('导出为 JSON')),
                      PopupMenuItem(value: 'md', child: Text('导出为 Markdown')),
                      PopupMenuItem(value: 'csv', child: Text('导出为 CSV')),
                    ],
                  ),
                if (_list.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.delete_sweep, color: gradeBad),
                    tooltip: '清空全部历史',
                    onPressed: _confirmClear,
                  ),
              ],
      ),
      body: _loading
          ? const Center(child: DivinationLoadingIndicator(size: 56))
          : _list.isEmpty
          ? Center(
              child: Text('暂无历史记录', style: TextStyle(color: c.textHint)),
            )
          : Column(
              children: [
                _buildFilterBar(c),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            '无匹配记录',
                            style: TextStyle(color: c.textHint),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) =>
                              _buildItem(c, filtered[i]),
                        ),
                ),
              ],
            ),
    );
  }

  /// 搜索框 + 术数筛选条（v2.12.0）。
  Widget _buildFilterBar(AppClr c) {
    final techs = _distinctTechs();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(color: c.textPrimary, fontSize: AppFontSize.body),
            cursorColor: c.gold,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search, color: c.textSubtitle, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: c.textSubtitle, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              hintText: '搜索摘要 / 术数 / 备注…',
              hintStyle: TextStyle(color: c.textHint, fontSize: AppFontSize.bodySmall),
              filled: true,
              fillColor: c.panel,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: BorderSide(color: c.goldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: BorderSide(color: c.goldBright, width: 1.2),
              ),
            ),
          ),
          if (techs.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: techs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final t = techs[i];
                  final selected = _filterTech == t.techId;
                  return _techChip(c, t.techName, t.techId, selected);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _techChip(AppClr c, String label, String id, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _filterTech = selected ? null : id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? c.gold.withValues(alpha: 0.18) : c.panel,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(color: selected ? c.gold : c.goldBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c.goldBright : c.textBody,
            fontSize: AppFontSize.label,
            fontWeight: selected ? AppFontWeight.bold : AppFontWeight.regular,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(AppClr c, HistoryEntry e) {
    final selected = _selected.contains(e.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecorativePanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.panel),
          ),
          leading: _selectMode
              ? Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? c.goldBright : c.textHint,
                  size: 22,
                )
              : null,
          title: Text(
            '${e.techName} · ${e.summary}',
            style: TextStyle(
              color: c.goldBright,
              fontSize: AppFontSize.body,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                e.time.toString().substring(0, 19),
                style: TextStyle(color: c.textMeta, fontSize: AppFontSize.caption),
              ),
              if (e.note != null && e.note!.isNotEmpty)
                Text(
                  '备注：${e.note}',
                  style: TextStyle(color: c.textBody, fontSize: AppFontSize.label),
                ),
            ],
          ),
          trailing: _selectMode
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.replay,
                        color: e.extra != null ? c.gold : c.textHint,
                        size: 20,
                      ),
                      tooltip: e.extra != null ? '恢复卦象' : '旧记录不支持恢复',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: e.extra != null ? () => _restore(e) : null,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy_all,
                        color: c.textSubtitle,
                        size: 20,
                      ),
                      tooltip: '复制',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: () => _copyEntry(e),
                    ),
                    Icon(Icons.chevron_right, color: c.textSubtitle),
                  ],
                ),
          onTap: _selectMode
              ? () => _toggleSelected(e.id)
              : () => _openDetail(e),
          onLongPress: _selectMode
              ? null
              : () => setState(() {
                  _selectMode = true;
                  _selected.add(e.id);
                }),
        ),
      ),
    );
  }
}
