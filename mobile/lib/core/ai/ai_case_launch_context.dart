// Copyright (c) 2026 Qore
import '../history/history_store.dart';

/// Immutable payload for opening AI interpretation from a technique result.
///
/// [historyEntryId] is present only when the result is already saved in local
/// history. A live result can use the regular constructor without implying
/// that a history row exists.
class AiCaseLaunchContext {
  final String techId;
  final String techName;
  final String summary;
  final String detail;
  final DateTime time;
  final String? historyEntryId;
  final String? note;

  const AiCaseLaunchContext({
    required this.techId,
    required this.techName,
    required this.summary,
    required this.detail,
    required this.time,
    this.historyEntryId,
    this.note,
  });

  factory AiCaseLaunchContext.fromHistoryEntry(HistoryEntry entry) =>
      AiCaseLaunchContext(
        techId: entry.techId,
        techName: entry.techName,
        summary: entry.summary,
        detail: entry.detail,
        time: entry.time,
        historyEntryId: entry.id,
        note: entry.note,
      );
}
