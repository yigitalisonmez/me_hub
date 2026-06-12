import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/core/reminders/data/reminder_preferences_repository.dart';
import 'package:me_hub/core/reminders/domain/reminder_feature.dart';
import 'package:me_hub/core/reminders/domain/reminder_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults keep all feature reminders opt-in', () {
    final preferences = ReminderPreferences.defaults();

    expect(preferences.masterEnabled, isFalse);
    for (final feature in ReminderFeature.values) {
      expect(preferences.isEnabled(feature), isFalse);
    }
    expect(preferences.waterIntervalHours, 2);
  });

  test('serializes enabled features, times, and water settings', () {
    final original = ReminderPreferences.defaults(masterEnabled: true)
        .setFeatureEnabled(ReminderFeature.mood, true)
        .setFeatureTime(
          ReminderFeature.mood,
          const ReminderTime(hour: 21, minute: 15),
        )
        .copyWith(
          waterStart: const ReminderTime(hour: 20, minute: 0),
          waterEnd: const ReminderTime(hour: 6, minute: 0),
          waterIntervalHours: 3,
        );

    final restored = ReminderPreferences.fromJson(original.toJson());

    expect(restored.masterEnabled, isTrue);
    expect(restored.isEnabled(ReminderFeature.mood), isTrue);
    expect(
      restored.timeFor(ReminderFeature.mood),
      const ReminderTime(hour: 21, minute: 15),
    );
    expect(restored.waterStart, const ReminderTime(hour: 20, minute: 0));
    expect(restored.waterEnd, const ReminderTime(hour: 6, minute: 0));
    expect(restored.waterIntervalHours, 3);
  });

  test('first load migrates once and preserves the saved document', () async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final repository = ReminderPreferencesRepository(sharedPreferences);

    final first = await repository.load(hasLegacyReminders: true);
    final second = await repository.load(hasLegacyReminders: false);

    expect(first.didMigrate, isTrue);
    expect(first.preferences.masterEnabled, isTrue);
    expect(second.didMigrate, isFalse);
    expect(second.preferences.masterEnabled, isTrue);
  });

  test('invalid persisted values recover to bounded defaults', () {
    final restored = ReminderPreferences.fromJson({
      'masterEnabled': true,
      'waterIntervalHours': 1,
      'waterStart': {'hour': 99, 'minute': 0},
    });

    expect(restored.masterEnabled, isTrue);
    expect(restored.waterIntervalHours, 2);
    expect(restored.waterStart, const ReminderTime(hour: 8, minute: 0));
  });
}
