import 'calendar_event.dart';

/// Notification reminder offset times
enum ReminderOffset {
  fiveMinutes,
  fifteenMinutes,
  thirtyMinutes,
  oneHour,
  threeHours,
  twelveHours,
  oneDay,
}

/// Extension methods for ReminderOffset
extension ReminderOffsetExtension on ReminderOffset {
  /// Get the duration for the reminder offset
  Duration get duration {
    switch (this) {
      case ReminderOffset.fiveMinutes:
        return const Duration(minutes: 5);
      case ReminderOffset.fifteenMinutes:
        return const Duration(minutes: 15);
      case ReminderOffset.thirtyMinutes:
        return const Duration(minutes: 30);
      case ReminderOffset.oneHour:
        return const Duration(hours: 1);
      case ReminderOffset.threeHours:
        return const Duration(hours: 3);
      case ReminderOffset.twelveHours:
        return const Duration(hours: 12);
      case ReminderOffset.oneDay:
        return const Duration(days: 1);
    }
  }

  /// User-friendly display name
  String get displayName {
    switch (this) {
      case ReminderOffset.fiveMinutes:
        return '5 minutes before';
      case ReminderOffset.fifteenMinutes:
        return '15 minutes before';
      case ReminderOffset.thirtyMinutes:
        return '30 minutes before';
      case ReminderOffset.oneHour:
        return '1 hour before';
      case ReminderOffset.threeHours:
        return '3 hours before';
      case ReminderOffset.twelveHours:
        return '12 hours before';
      case ReminderOffset.oneDay:
        return '1 day before';
    }
  }

  /// Short display name for compact UI
  String get shortName {
    switch (this) {
      case ReminderOffset.fiveMinutes:
        return '5m';
      case ReminderOffset.fifteenMinutes:
        return '15m';
      case ReminderOffset.thirtyMinutes:
        return '30m';
      case ReminderOffset.oneHour:
        return '1h';
      case ReminderOffset.threeHours:
        return '3h';
      case ReminderOffset.twelveHours:
        return '12h';
      case ReminderOffset.oneDay:
        return '1d';
    }
  }

  /// Convert to HiveReminderOffset for persistence
  HiveReminderOffset toHiveReminderOffset() {
    switch (this) {
      case ReminderOffset.fiveMinutes:
        return HiveReminderOffset.fiveMinutes;
      case ReminderOffset.fifteenMinutes:
        return HiveReminderOffset.fifteenMinutes;
      case ReminderOffset.thirtyMinutes:
        return HiveReminderOffset.thirtyMinutes;
      case ReminderOffset.oneHour:
        return HiveReminderOffset.oneHour;
      case ReminderOffset.threeHours:
        return HiveReminderOffset.threeHours;
      case ReminderOffset.twelveHours:
        return HiveReminderOffset.twelveHours;
      case ReminderOffset.oneDay:
        return HiveReminderOffset.oneDay;
    }
  }
}
