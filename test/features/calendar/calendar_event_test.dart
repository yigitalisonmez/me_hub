import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/features/calendar/domain/entities/calendar_event.dart';

// CalendarEvent extends HiveObject but notificationTime / isPast are pure
// computed properties — no Hive box interaction, no platform channels needed.
void main() {
  CalendarEvent makeEvent({
    required DateTime eventTime,
    HiveReminderOffset offset = HiveReminderOffset.thirtyMinutes,
    bool hasReminder = true,
  }) {
    return CalendarEvent(
      id: 'ev-1',
      title: 'Test Event',
      dateTime: eventTime,
      reminderOffset: offset,
      hasReminder: hasReminder,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('CalendarEvent.notificationTime', () {
    test('5-minute offset fires 5 min before event', () {
      final t = DateTime(2026, 6, 5, 14, 30);
      final e = makeEvent(eventTime: t, offset: HiveReminderOffset.fiveMinutes);
      expect(e.notificationTime, t.subtract(const Duration(minutes: 5)));
    });

    test('15-minute offset fires 15 min before event', () {
      final t = DateTime(2026, 6, 5, 10, 0);
      final e = makeEvent(eventTime: t, offset: HiveReminderOffset.fifteenMinutes);
      expect(e.notificationTime, t.subtract(const Duration(minutes: 15)));
    });

    test('30-minute offset fires 30 min before event', () {
      final t = DateTime(2026, 6, 5, 9, 0);
      final e = makeEvent(eventTime: t, offset: HiveReminderOffset.thirtyMinutes);
      expect(e.notificationTime, t.subtract(const Duration(minutes: 30)));
    });

    test('1-hour offset fires 1 hour before event', () {
      final t = DateTime(2026, 6, 5, 12, 0);
      final e = makeEvent(eventTime: t, offset: HiveReminderOffset.oneHour);
      expect(e.notificationTime, t.subtract(const Duration(hours: 1)));
    });

    test('3-hour offset fires 3 hours before event', () {
      final t = DateTime(2026, 6, 5, 15, 0);
      final e = makeEvent(eventTime: t, offset: HiveReminderOffset.threeHours);
      expect(e.notificationTime, t.subtract(const Duration(hours: 3)));
    });

    test('12-hour offset fires 12 hours before event', () {
      final t = DateTime(2026, 6, 5, 20, 0);
      final e = makeEvent(eventTime: t, offset: HiveReminderOffset.twelveHours);
      expect(e.notificationTime, t.subtract(const Duration(hours: 12)));
    });

    test('1-day offset fires 24 hours before event', () {
      final t = DateTime(2026, 6, 5, 9, 0);
      final e = makeEvent(eventTime: t, offset: HiveReminderOffset.oneDay);
      expect(e.notificationTime, t.subtract(const Duration(days: 1)));
    });
  });

  group('CalendarEvent.isPast', () {
    test('past event is isPast = true', () {
      final e = makeEvent(eventTime: DateTime(2020, 1, 1, 9, 0));
      expect(e.isPast, isTrue);
    });

    test('future event is isPast = false', () {
      final future = DateTime.now().add(const Duration(hours: 24));
      final e = makeEvent(eventTime: future);
      expect(e.isPast, isFalse);
    });
  });

  group('CalendarEvent.hasReminder', () {
    test('hasReminder = false means notification should not be scheduled', () {
      final e = makeEvent(
        eventTime: DateTime.now().add(const Duration(hours: 2)),
        hasReminder: false,
      );
      expect(e.hasReminder, isFalse);
    });
  });
}
