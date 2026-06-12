import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ReminderIdRegistry {
  static const _storageKey = 'reminder_notification_ids_v1';
  static const _maxId = 0x7fffffff;
  static const _reservedIds = {9001, 999999};

  final SharedPreferences _preferences;
  Map<String, int>? _ids;

  ReminderIdRegistry(this._preferences);

  static Future<ReminderIdRegistry> create() async {
    return ReminderIdRegistry(await SharedPreferences.getInstance());
  }

  Future<int> idFor(String logicalKey) async {
    final ids = await _load();
    final existing = ids[logicalKey];
    if (existing != null) return existing;

    var candidate = _fnv1a(logicalKey);
    final used = ids.values.toSet()..addAll(_reservedIds);
    while (used.contains(candidate)) {
      candidate = candidate == _maxId ? 1 : candidate + 1;
    }
    ids[logicalKey] = candidate;
    await _save();
    return candidate;
  }

  Future<Map<String, int>> entriesForNamespace(String namespace) async {
    final ids = await _load();
    final prefix = '$namespace:';
    return {
      for (final entry in ids.entries)
        if (entry.key.startsWith(prefix)) entry.key: entry.value,
    };
  }

  Future<void> removeKeys(Iterable<String> logicalKeys) async {
    final ids = await _load();
    var changed = false;
    for (final key in logicalKeys) {
      changed = ids.remove(key) != null || changed;
    }
    if (changed) await _save();
  }

  Future<void> clear() async {
    _ids = {};
    await _preferences.remove(_storageKey);
  }

  Future<Map<String, int>> _load() async {
    if (_ids != null) return _ids!;
    final raw = _preferences.getString(_storageKey);
    if (raw == null) return _ids = {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return _ids = {
          for (final entry in decoded.entries)
            if (entry.key is String && entry.value is int)
              entry.key as String: entry.value as int,
        };
      }
    } catch (_) {}
    return _ids = {};
  }

  Future<void> _save() async {
    await _preferences.setString(_storageKey, jsonEncode(_ids));
  }

  int _fnv1a(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return (hash & _maxId).clamp(1, _maxId);
  }
}
