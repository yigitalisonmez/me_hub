import 'package:hive/hive.dart';
import 'reminder_offset.dart';

part 'calendar_event.g.dart';

/// Hive adapter için ReminderOffset
@HiveType(typeId: 61)
enum HiveReminderOffset {
  @HiveField(0)
  fiveMinutes,
  @HiveField(1)
  fifteenMinutes,
  @HiveField(2)
  thirtyMinutes,
  @HiveField(3)
  oneHour,
  @HiveField(4)
  threeHours,
  @HiveField(5)
  twelveHours,
  @HiveField(6)
  oneDay,
}

/// Takvim etkinliği entity'si
@HiveType(typeId: 60)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final DateTime dateTime;

  @HiveField(4)
  final HiveReminderOffset reminderOffset;

  @HiveField(5)
  final bool isCompleted;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final bool hasReminder;

  @HiveField(8)
  final String? categoryId; // Reference to EventCategory

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    required this.reminderOffset,
    this.isCompleted = false,
    required this.createdAt,
    this.hasReminder = true,
    this.categoryId,
  });

  /// ReminderOffset'e dönüştür
  ReminderOffset get reminderOffsetEnum {
    switch (reminderOffset) {
      case HiveReminderOffset.fiveMinutes:
        return ReminderOffset.fiveMinutes;
      case HiveReminderOffset.fifteenMinutes:
        return ReminderOffset.fifteenMinutes;
      case HiveReminderOffset.thirtyMinutes:
        return ReminderOffset.thirtyMinutes;
      case HiveReminderOffset.oneHour:
        return ReminderOffset.oneHour;
      case HiveReminderOffset.threeHours:
        return ReminderOffset.threeHours;
      case HiveReminderOffset.twelveHours:
        return ReminderOffset.twelveHours;
      case HiveReminderOffset.oneDay:
        return ReminderOffset.oneDay;
    }
  }

  /// HiveReminderOffset'e dönüştür
  static HiveReminderOffset toHiveOffset(ReminderOffset offset) {
    switch (offset) {
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

  /// Bildirim zamanını hesapla
  DateTime get notificationTime =>
      dateTime.subtract(reminderOffsetEnum.duration);

  /// Bu etkinlik geçmiş mi?
  bool get isPast => dateTime.isBefore(DateTime.now());

  /// Bu etkinlik bugün mü?
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Kopyala ve güncelle
  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    HiveReminderOffset? reminderOffset,
    bool? isCompleted,
    DateTime? createdAt,
    bool? hasReminder,
    String? categoryId,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      reminderOffset: reminderOffset ?? this.reminderOffset,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      hasReminder: hasReminder ?? this.hasReminder,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  /// Tamamlandı olarak işaretle
  CalendarEvent markAsCompleted() => copyWith(isCompleted: true);

  /// Tamamlanmadı olarak işaretle
  CalendarEvent markAsIncomplete() => copyWith(isCompleted: false);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CalendarEvent(id: $id, title: $title, dateTime: $dateTime, isCompleted: $isCompleted)';
  }
}
