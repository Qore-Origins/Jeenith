// Copyright (c) 2026 Qore
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jeenith/core/ai/jiekua_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('upsert keeps cases ordered by most recent update', () async {
    final older = _session('older', DateTime.utc(2026, 9, 24));
    final newer = _session('newer', DateTime.utc(2026, 9, 25));
    final revisedOlder = older.copyWith(updatedAt: DateTime.utc(2026, 9, 26));

    await JiekuaStore.upsert(older);
    await JiekuaStore.upsert(newer);
    await JiekuaStore.upsert(revisedOlder);

    final saved = await JiekuaStore.load();
    expect(saved.map((session) => session.id), ['older', 'newer']);
  });

  test('remove deletes only the selected case', () async {
    await JiekuaStore.upsert(_session('keep', DateTime.utc(2026, 9, 25)));
    await JiekuaStore.upsert(_session('remove', DateTime.utc(2026, 9, 26)));

    await JiekuaStore.remove('remove');

    final saved = await JiekuaStore.load();
    expect(saved.map((session) => session.id), ['keep']);
  });
}

JiekuaSession _session(String id, DateTime updatedAt) => JiekuaSession(
  id: id,
  techName: '周易',
  summary: id,
  hexuanText: '结果',
  createdAt: DateTime.utc(2026, 9, 24),
  updatedAt: updatedAt,
  messages: const [],
);
