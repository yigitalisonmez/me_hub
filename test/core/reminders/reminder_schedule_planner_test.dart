import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/core/reminders/domain/reminder_feature.dart';
import 'package:me_hub/core/reminders/domain/reminder_preferences.dart';
import 'package:me_hub/core/reminders/domain/reminder_request.dart';
import 'package:me_hub/core/reminders/services/reminder_schedule_planner.dart';

void main() {
  const planner = ReminderSchedulePlanner();

  ReminderPreferences enabledPreferences(ReminderFeature feature) {
    return ReminderPreferences.defaults(
      masterEnabled: true,
    ).setFeatureEnabled(feature, true);
  }

  test('daily completion moves the next occurrence to tomorrow', () {
    final preferences = enabledPreferences(ReminderFeature.mood).setFeatureTime(
      ReminderFeature.mood,
      const ReminderTime(hour: 20, minute: 0),
    );
    final now = DateTime(2026, 6, 8, 9);

    final pending = planner.dailyFeature(
      feature: ReminderFeature.mood,
      preferences: preferences,
      now: now,
      completedToday: false,
      actionable: true,
      title: 'Mood',
      body: 'Check in',
      payload: 'kora://mood',
    );
    final completed = planner.dailyFeature(
      feature: ReminderFeature.mood,
      preferences: preferences,
      now: now,
      completedToday: true,
      actionable: true,
      title: 'Mood',
      body: 'Check in',
      payload: 'kora://mood',
    );

    expect(pending.single.scheduledAt, DateTime(2026, 6, 8, 20));
    expect(completed.single.scheduledAt, DateTime(2026, 6, 9, 20));
  });

  test('undo restores a still-future daily occurrence today', () {
    final preferences = enabledPreferences(ReminderFeature.breathing)
        .setFeatureTime(
          ReminderFeature.breathing,
          const ReminderTime(hour: 18, minute: 0),
        );

    final requests = planner.dailyFeature(
      feature: ReminderFeature.breathing,
      preferences: preferences,
      now: DateTime(2026, 6, 8, 17),
      completedToday: false,
      actionable: true,
      title: 'Breathe',
      body: 'Take a pause',
      payload: 'kora://breathing',
    );

    expect(requests.single.scheduledAt, DateTime(2026, 6, 8, 18));
  });

  test(
    'todo uses a one-shot request only while today review time is future',
    () {
      final preferences = enabledPreferences(ReminderFeature.todo)
          .setFeatureTime(
            ReminderFeature.todo,
            const ReminderTime(hour: 18, minute: 30),
          );

      final futureRequest = planner.dailyFeature(
        feature: ReminderFeature.todo,
        preferences: preferences,
        now: DateTime(2026, 6, 8, 17),
        completedToday: false,
        actionable: true,
        title: 'Tasks',
        body: 'Review tasks',
        payload: 'kora://todo',
      );
      final pastRequest = planner.dailyFeature(
        feature: ReminderFeature.todo,
        preferences: preferences,
        now: DateTime(2026, 6, 8, 19),
        completedToday: false,
        actionable: true,
        title: 'Tasks',
        body: 'Review tasks',
        payload: 'kora://todo',
      );

      expect(futureRequest.single.repeat, ReminderRepeat.none);
      expect(futureRequest.single.scheduledAt, DateTime(2026, 6, 8, 18, 30));
      expect(pastRequest, isEmpty);
    },
  );

  test('water creates bounded slots across midnight', () {
    final preferences = enabledPreferences(ReminderFeature.water).copyWith(
      waterStart: const ReminderTime(hour: 20, minute: 0),
      waterEnd: const ReminderTime(hour: 6, minute: 0),
      waterIntervalHours: 2,
    );

    final requests = planner.water(
      preferences: preferences,
      now: DateTime(2026, 6, 8, 19),
      goalReached: false,
    );

    expect(
      requests.map((request) => request.logicalKey),
      containsAll([
        'feature:water:slot:20:00',
        'feature:water:slot:22:00',
        'feature:water:slot:00:00',
        'feature:water:slot:02:00',
        'feature:water:slot:04:00',
        'feature:water:slot:06:00',
      ]),
    );
    expect(requests, hasLength(6));
    expect(
      requests
          .firstWhere((request) => request.logicalKey.endsWith('00:00'))
          .scheduledAt,
      DateTime(2026, 6, 9),
    );
  });

  test('reaching the water goal starts every slot on a future day', () {
    final preferences = enabledPreferences(ReminderFeature.water).copyWith(
      waterStart: const ReminderTime(hour: 8, minute: 0),
      waterEnd: const ReminderTime(hour: 12, minute: 0),
      waterIntervalHours: 2,
    );
    final now = DateTime(2026, 6, 8, 7);

    final requests = planner.water(
      preferences: preferences,
      now: now,
      goalReached: true,
    );

    expect(requests.every((request) => request.scheduledAt.day == 9), isTrue);
  });
}
