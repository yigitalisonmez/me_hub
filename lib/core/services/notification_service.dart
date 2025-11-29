import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../features/routines/domain/entities/routine.dart';

class NotificationService {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'routine_reminders',
          'Rutin Hatırlatıcıları',
          description: 'Rutinleriniz için hatırlatmalar',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'test_channel',
          'Test Bildirimleri',
          description: 'Uygulama test bildirimleri',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidImplementation.requestNotificationsPermission();

      final canScheduleExactAlarms = await androidImplementation
          .canScheduleExactNotifications();

      if (canScheduleExactAlarms == false) {
        await androidImplementation.requestExactAlarmsPermission();
      }
    }

    _initialized = true;
  }

  /// Bildirime tıklandığında çalışacak fonksiyon
  void _onNotificationTapped(NotificationResponse response) {
    // Navigasyon işlemleri buraya eklenebilir
  }

  /// Tüm rutinlerin bildirimlerini yeniden planla
  Future<void> rescheduleAllRoutineNotifications(List<Routine> routines) async {
    if (!_initialized) await initialize();

    for (final routine in routines) {
      if (routine.time != null) {
        await scheduleRoutineNotifications(routine);
      }
    }
  }

  /// Bir rutin için (seçili günlerde) bildirim planla
  Future<void> scheduleRoutineNotifications(Routine routine) async {
    if (!_initialized) await initialize();

    await cancelRoutineNotifications(routine.id);

    if (routine.time == null) return;

    final time = routine.time!;
    final selectedDays = routine.selectedDays;

    final daysToSchedule = (selectedDays == null || selectedDays.isEmpty)
        ? [0, 1, 2, 3, 4, 5, 6]
        : selectedDays;

    for (final dayIndex in daysToSchedule) {
      await _scheduleNotificationForDay(
        routine: routine,
        dayIndex: dayIndex,
        hour: time.hour,
        minute: time.minute,
      );
    }
  }

  /// Belirli bir gün için saati hesaplayıp planlamayı başlatır
  Future<void> _scheduleNotificationForDay({
    required Routine routine,
    required int dayIndex,
    required int hour,
    required int minute,
  }) async {
    int notificationMinute = minute - 5;
    int notificationHour = hour;

    if (notificationMinute < 0) {
      notificationMinute += 60;
      notificationHour -= 1;
      if (notificationHour < 0) {
        notificationHour = 23;
      }
    }

    await _scheduleWeeklyRecurringNotification(
      routine: routine,
      dayIndex: dayIndex,
      hour: notificationHour,
      minute: notificationMinute,
    );
  }

  /// Haftalık tekrar eden bildirimi kurar
  Future<void> _scheduleWeeklyRecurringNotification({
    required Routine routine,
    required int dayIndex,
    required int hour,
    required int minute,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final nextDay = _getNextDayOfWeek(now, dayIndex);

      var scheduledDate = tz.TZDateTime(
        tz.local,
        nextDay.year,
        nextDay.month,
        nextDay.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      final notificationId = _getNotificationId(routine.id, dayIndex);

      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      bool canScheduleExact = false;
      if (androidImplementation != null) {
        final canSchedule = await androidImplementation
            .canScheduleExactNotifications();
        canScheduleExact = canSchedule ?? false;
      }

      const androidDetails = AndroidNotificationDetails(
        'routine_reminders',
        'Rutin Hatırlatıcıları',
        channelDescription: 'Rutinleriniz için hatırlatmalar',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notificationId,
        'Rutin Hatırlatıcı',
        '${routine.name} rutini 5 dakika sonra başlayacak!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: canScheduleExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e, stackTrace) {
      debugPrint('Rutin bildirimi zamanlama hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Bir sonraki haftanın gününü bulur
  tz.TZDateTime _getNextDayOfWeek(tz.TZDateTime now, int targetDay) {
    final currentWeekday = now.weekday;
    final targetWeekday = targetDay + 1;

    int daysUntilTarget = targetWeekday - currentWeekday;
    if (daysUntilTarget < 0) {
      daysUntilTarget += 7;
    }

    final targetDate = now.add(Duration(days: daysUntilTarget));
    return tz.TZDateTime(
      tz.local,
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
  }

  /// Bir rutine ait tüm bildirimleri iptal et
  Future<void> cancelRoutineNotifications(String routineId) async {
    for (int day = 0; day < 7; day++) {
      final notificationId = _getNotificationId(routineId, day);
      await _notifications.cancel(notificationId);
    }
  }

  /// Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Unique ID oluşturucu
  int _getNotificationId(String routineId, int dayIndex) {
    final idString = '${routineId}_$dayIndex';
    return idString.hashCode.abs() % 2147483647;
  }

  /// Rutin güncellendiğinde bildirimleri güncelle
  Future<void> updateRoutineNotifications(Routine routine) async {
    await scheduleRoutineNotifications(routine);
  }

  /// Test için 1 dakika sonra bildirim gönder
  Future<void> showTestNotification() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Bildirimleri',
        channelDescription: 'Uygulama test bildirimleri',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      Future.delayed(const Duration(minutes: 1), () async {
        await _notifications.show(
          999998,
          'Test Bildirimi',
          '1 dakika sonra bildirim geldi! 🎉',
          notificationDetails,
        );
      });

      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      bool canScheduleExact = false;
      if (androidImplementation != null) {
        final canSchedule = await androidImplementation
            .canScheduleExactNotifications();
        canScheduleExact = canSchedule ?? false;
      }

      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = now.add(const Duration(minutes: 1));

      await _notifications.zonedSchedule(
        999999,
        'Test Bildirimi',
        '1 dakika sonra bildirim geldi! 🎉',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: canScheduleExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e, stackTrace) {
      debugPrint('Bildirim gönderme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
