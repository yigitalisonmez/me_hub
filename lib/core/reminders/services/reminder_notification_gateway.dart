import '../domain/reminder_request.dart';

enum NotificationPermissionState { unknown, granted, denied }

abstract interface class ReminderNotificationGateway {
  Future<NotificationPermissionState> getPermissionState();

  Future<NotificationPermissionState> requestPermission();

  Future<void> openNotificationSettings();

  Future<void> scheduleReminder(int id, ReminderRequest request);

  Future<void> cancelNotification(int id);

  Future<void> cancelAllNotifications();
}
