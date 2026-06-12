import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reminder_preferences.dart';

class ReminderPreferencesLoadResult {
  final ReminderPreferences preferences;
  final bool didMigrate;

  const ReminderPreferencesLoadResult({
    required this.preferences,
    required this.didMigrate,
  });
}

class ReminderPreferencesRepository {
  static const _preferencesKey = 'reminder_preferences_v1';

  final SharedPreferences _preferences;

  ReminderPreferencesRepository(this._preferences);

  static Future<ReminderPreferencesRepository> create() async {
    return ReminderPreferencesRepository(await SharedPreferences.getInstance());
  }

  Future<ReminderPreferencesLoadResult> load({
    required bool hasLegacyReminders,
  }) async {
    final raw = _preferences.getString(_preferencesKey);
    if (raw == null) {
      final migrated = ReminderPreferences.defaults(
        masterEnabled: hasLegacyReminders,
      );
      await save(migrated);
      return ReminderPreferencesLoadResult(
        preferences: migrated,
        didMigrate: true,
      );
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ReminderPreferencesLoadResult(
          preferences: ReminderPreferences.fromJson(decoded),
          didMigrate: false,
        );
      }
    } catch (_) {}

    final recovered = ReminderPreferences.defaults(
      masterEnabled: hasLegacyReminders,
    );
    await save(recovered);
    return ReminderPreferencesLoadResult(
      preferences: recovered,
      didMigrate: true,
    );
  }

  Future<void> save(ReminderPreferences preferences) async {
    await _preferences.setString(
      _preferencesKey,
      jsonEncode(preferences.toJson()),
    );
  }
}
