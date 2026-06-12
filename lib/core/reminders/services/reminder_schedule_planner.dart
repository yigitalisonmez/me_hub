import '../domain/reminder_feature.dart';
import '../domain/reminder_preferences.dart';
import '../domain/reminder_request.dart';

class ReminderSchedulePlanner {
  const ReminderSchedulePlanner();

  List<ReminderRequest> dailyFeature({
    required ReminderFeature feature,
    required ReminderPreferences preferences,
    required DateTime now,
    required bool completedToday,
    required bool actionable,
    required String title,
    required String body,
    required String payload,
  }) {
    if (!preferences.masterEnabled ||
        !preferences.isEnabled(feature) ||
        !actionable) {
      return const [];
    }
    final time = preferences.timeFor(feature);
    final scheduledAt = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (feature == ReminderFeature.todo &&
        (completedToday || !scheduledAt.isAfter(now))) {
      return const [];
    }
    return [
      ReminderRequest(
        logicalKey: '${feature.namespace}:daily',
        namespace: feature.namespace,
        title: title,
        body: body,
        payload: payload,
        scheduledAt: feature == ReminderFeature.todo
            ? scheduledAt
            : nextDailyOccurrence(
                now: now,
                time: time,
                skipToday: completedToday,
              ),
        repeat: feature == ReminderFeature.todo
            ? ReminderRepeat.none
            : ReminderRepeat.daily,
      ),
    ];
  }

  List<ReminderRequest> water({
    required ReminderPreferences preferences,
    required DateTime now,
    required bool goalReached,
  }) {
    const feature = ReminderFeature.water;
    if (!preferences.masterEnabled || !preferences.isEnabled(feature)) {
      return const [];
    }

    final start = preferences.waterStart.minutesSinceMidnight;
    final end = preferences.waterEnd.minutesSinceMidnight;
    final windowMinutes = end >= start ? end - start : (24 * 60 - start) + end;

    final result = <ReminderRequest>[];
    for (
      var offset = 0;
      offset <= windowMinutes;
      offset += preferences.waterIntervalHours * 60
    ) {
      final minute = (start + offset) % (24 * 60);
      final time = ReminderTime(hour: minute ~/ 60, minute: minute % 60);
      result.add(
        ReminderRequest(
          logicalKey: '${feature.namespace}:slot:${time.label}',
          namespace: feature.namespace,
          title: 'Time for some water',
          body: 'A small glass now makes today’s goal easier.',
          payload: 'kora://water',
          scheduledAt: nextDailyOccurrence(
            now: now,
            time: time,
            skipToday: goalReached,
          ),
          repeat: ReminderRepeat.daily,
        ),
      );
    }
    return result;
  }

  ReminderRequest weeklyInsight({
    required ReminderPreferences preferences,
    required DateTime now,
    required String insight,
    required String userName,
  }) {
    final time = preferences.timeFor(ReminderFeature.weeklyInsights);
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day + daysUntilSunday,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return ReminderRequest(
      logicalKey: '${ReminderFeature.weeklyInsights.namespace}:weekly',
      namespace: ReminderFeature.weeklyInsights.namespace,
      title: 'Your Kora insight',
      body: '$userName, this week: $insight',
      payload: 'kora://home',
      scheduledAt: scheduled,
      repeat: ReminderRepeat.weekly,
    );
  }

  DateTime nextDailyOccurrence({
    required DateTime now,
    required ReminderTime time,
    bool skipToday = false,
  }) {
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (skipToday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
