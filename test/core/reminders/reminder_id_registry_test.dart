import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/core/reminders/services/reminder_id_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('keeps IDs stable across registry recreation', () async {
    final preferences = await SharedPreferences.getInstance();
    final firstRegistry = ReminderIdRegistry(preferences);
    final firstId = await firstRegistry.idFor('routine:morning:weekday:1');

    final secondRegistry = ReminderIdRegistry(preferences);
    final secondId = await secondRegistry.idFor('routine:morning:weekday:1');

    expect(secondId, firstId);
    expect(firstId, greaterThan(0));
  });

  test('isolates namespace lookups and stale-key removal', () async {
    final preferences = await SharedPreferences.getInstance();
    final registry = ReminderIdRegistry(preferences);
    await registry.idFor('feature:mood:daily');
    await registry.idFor('feature:water:slot:08:00');
    await registry.idFor('routine:morning:weekday:1');

    final featureEntries = await registry.entriesForNamespace('feature');
    expect(featureEntries, hasLength(2));

    await registry.removeKeys(['feature:mood:daily']);
    final moodEntries = await registry.entriesForNamespace('feature:mood');
    final waterEntries = await registry.entriesForNamespace('feature:water');
    expect(moodEntries, isEmpty);
    expect(waterEntries, hasLength(1));
  });

  test('resolves hash collisions without reusing an ID', () async {
    final preferences = await SharedPreferences.getInstance();
    final registry = ReminderIdRegistry(preferences);

    final first = await registry.idFor('collision:816691');
    final second = await registry.idFor('collision:1011240');

    expect(first, 236422326);
    expect(second, first + 1);
  });
}
