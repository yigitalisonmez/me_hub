import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../features/routines/domain/entities/routine.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../features/calendar/domain/entities/calendar_event.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._withPlugin(
    FlutterLocalNotificationsPlugin(),
  );
  factory NotificationService() => _instance;
  NotificationService._withPlugin(this._notifications);

  /// Creates an isolated instance for testing — does not affect the singleton.
  @visibleForTesting
  static NotificationService createForTesting(
    FlutterLocalNotificationsPlugin plugin,
  ) => NotificationService._withPlugin(plugin);

  FlutterLocalNotificationsPlugin _notifications;

  bool _initialized = false;
  tz.Location? _localLocation;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    try {
      final String deviceTimezone = await FlutterTimezone.getLocalTimezone();
      _localLocation = tz.getLocation(deviceTimezone);
    } catch (_) {
      _localLocation = tz.UTC;
    }
    tz.setLocalLocation(_localLocation!);

    if (kDebugMode) {
      debugPrint('✅ Timezone set: ${_localLocation!.name}');
    }

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
          showBadge: true,
        ),
      );

      // Takvim bildirimleri kanalı
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'calendar_reminders',
          'Takvim Hatırlatıcıları',
          description: 'Takvim etkinlikleriniz için hatırlatmalar',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );

      // Haftalık içgörü bildirimleri kanalı
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'kora_insights',
          'Kora Öngörüleri',
          description: 'Kora uygulamasından haftalık kişisel öngörüler',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: false,
          showBadge: false,
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

  void _onNotificationTapped(NotificationResponse response) {
    // Navigasyon işlemleri buraya eklenebilir
  }

  Future<void> rescheduleAllRoutineNotifications(List<Routine> routines) async {
    if (!_initialized) await initialize();

    // Cancel only routine-specific IDs — do NOT use cancelAllNotifications()
    // which would also wipe calendar and insight notifications.
    for (final routine in routines) {
      await cancelRoutineNotifications(routine.id);
    }

    for (final routine in routines) {
      if (routine.time != null) {
        await scheduleRoutineNotifications(routine);
      }
    }
  }

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

  Future<void> _scheduleNotificationForDay({
    required Routine routine,
    required int dayIndex,
    required int hour,
    required int minute,
  }) async {
    // 5 dakika önceki saati hesapla
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
      notificationHour: notificationHour,
      notificationMinute: notificationMinute,
      routineHour: hour,
      routineMinute: minute,
    );
  }

  Future<void> _scheduleWeeklyRecurringNotification({
    required Routine routine,
    required int dayIndex,
    required int notificationHour,
    required int notificationMinute,
    required int routineHour,
    required int routineMinute,
  }) async {
    try {
      final location = _localLocation ?? tz.local;
      final now = tz.TZDateTime.now(location);

      // Hedef günü bul (0=Pazartesi, 6=Pazar)
      final currentWeekday =
          (now.weekday % 7); // 0=Pazar, 1=Pazartesi, ..., 6=Cumartesi

      // dayIndex'i DateTime.weekday sistemine çevir
      // dayIndex: 0=Pazartesi -> weekday: 1
      final targetWeekday = (dayIndex + 1) % 7; // 0=Pazar, 1=Pazartesi

      int daysUntilTarget;
      if (currentWeekday == 0) {
        // Bugün Pazar ise
        daysUntilTarget = targetWeekday == 0 ? 0 : targetWeekday;
      } else {
        daysUntilTarget = targetWeekday - currentWeekday;
        if (daysUntilTarget < 0) {
          daysUntilTarget += 7;
        }
      }

      // İlk bildirim tarihini hesapla
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        notificationHour,
        notificationMinute,
      ).add(Duration(days: daysUntilTarget));

      // Eğer hesaplanan tarih geçmişte kaldıysa, bir hafta ekle
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
        autoCancel: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Logging removed to reduce console spam

      // Random motivational quote
      final quotes = [
        'Five minutes to go—show up for yourself today.',
        'Your future self is thanking you already. Time to begin.',
        'Small actions shape big destinies. Ready? ${routine.name} will start in 5 minutes.',
        'Consistency beats motivation. Start now. ${routine.name} will start in 5 minutes.',
        'You’re one step away from progress—take it. ${routine.name} will start in 5 minutes.',
        'Discipline is choosing what you want most. It’s time. ${routine.name} will start in 5 minutes.',
        'A better day begins with a small habit. Let’s go. ${routine.name} will start in 5 minutes.',
        'Do it today, so tomorrow feels lighter. ${routine.name} will start in 5 minutes.',
        'Growth happens in quiet moments like this. Begin. ${routine.name} will start in 5 minutes.',
        'You don’t need perfection—just the next five minutes. ${routine.name} will start in 5 minutes.',
      ];
      final randomQuote = (quotes..shuffle()).first;

      await _notifications.zonedSchedule(
        notificationId,
        'Rutin Hatırlatıcı',
        randomQuote,
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
      debugPrint('❌ Bildirim zamanlama hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> cancelRoutineNotifications(String routineId) async {
    for (int day = 0; day < 7; day++) {
      final notificationId = _getNotificationId(routineId, day);
      await _notifications.cancel(notificationId);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    if (!_initialized) await initialize();
    await _notifications.cancel(id);
  }

  Future<void> checkPendingNotifications() async {
    if (!_initialized) await initialize();
    // Removed verbose logging
    await _notifications.pendingNotificationRequests();
  }

  int _getNotificationId(String routineId, int dayIndex) {
    final idString = '${routineId}_$dayIndex';
    return idString.hashCode.abs() % 2147483647;
  }

  Future<void> updateRoutineNotifications(Routine routine) async {
    await scheduleRoutineNotifications(routine);
  }

  Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        'routine_reminders',
        'Rutin Hatırlatıcıları',
        channelDescription: 'Test bildirimi',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Hemen bildirimi göster
      await _notifications.show(
        999999,
        'Test Bildirimi',
        'Bildirim başarıyla gönderildi! 🎉',
        notificationDetails,
      );

      debugPrint('✅ Test bildirimi hemen gönderildi');
    } catch (e, stackTrace) {
      debugPrint('❌ Test bildirimi hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ==================== HAFTALIK İÇGÖRÜ BİLDİRİMİ ====================

  /// Schedules (or reschedules) the weekly insight notification for next Sunday
  /// at 20:00 in the device timezone. Call on every app open after computing
  /// the current correlation. If [insight] has meaningful content, schedules;
  /// caller should call cancelNotification(9001) when insight is null.
  ///
  /// Notification ID 9001 is reserved exclusively for this insight.
  Future<void> scheduleWeeklyInsight(String insight, String userName) async {
    if (!_initialized) await initialize();

    const insightNotificationId = 9001;

    final location = _localLocation ?? tz.local;
    final now = tz.TZDateTime.now(location);

    // Calculate next Sunday 20:00 in local timezone.
    // Dart DateTime.weekday: 1=Monday … 7=Sunday
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    var nextSunday = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      20,
      0,
      0,
    ).add(Duration(days: daysUntilSunday));

    if (nextSunday.isBefore(now)) {
      nextSunday = nextSunday.add(const Duration(days: 7));
    }

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    bool canScheduleExact = false;
    if (androidImplementation != null) {
      canScheduleExact =
          (await androidImplementation.canScheduleExactNotifications()) ??
          false;
    }

    const androidDetails = AndroidNotificationDetails(
      'kora_insights',
      'Kora Öngörüleri',
      channelDescription: 'Kora uygulamasından haftalık kişisel öngörüler',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      enableVibration: false,
      playSound: true,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Cancel any previously scheduled insight notification before rescheduling.
    await _notifications.cancel(insightNotificationId);

    await _notifications.zonedSchedule(
      insightNotificationId,
      'Kora Öngörüsü',
      '$userName, bu hafta: $insight',
      nextSunday,
      notificationDetails,
      androidScheduleMode: canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    if (kDebugMode) {
      debugPrint('✅ Haftalık öngörü bildirimi zamanlandı: $nextSunday');
      debugPrint('   İçerik: $insight');
    }
  }

  // ==================== TAKVIM BİLDİRİMLERİ ====================

  /// Takvim etkinliği için bildirim zamanla
  Future<void> scheduleCalendarEventNotification(CalendarEvent event) async {
    if (!_initialized) await initialize();
    if (!event.hasReminder) return;

    // Geçmiş etkinlikler için bildirim zamanlamayı atla
    final notificationTime = event.notificationTime;
    if (notificationTime.isBefore(DateTime.now())) {
      if (kDebugMode) {
        debugPrint('⏭️ Takvim bildirimi atlandı (geçmiş): ${event.title}');
      }
      return;
    }

    try {
      final location = _localLocation ?? tz.local;
      final scheduledDate = tz.TZDateTime.from(notificationTime, location);

      final notificationId = _getCalendarNotificationId(event.id);

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
        'calendar_reminders',
        'Takvim Hatırlatıcıları',
        channelDescription: 'Takvim etkinlikleriniz için hatırlatmalar',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notificationId,
        '📅 ${event.title}',
        event.description ?? 'Etkinlik zamanı yaklaşıyor!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: canScheduleExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      if (kDebugMode) {
        debugPrint(
          '✅ Takvim bildirimi zamanlandı: ${event.title} - $scheduledDate',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Takvim bildirimi zamanlama hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Takvim etkinliği bildirimini iptal et
  Future<void> cancelCalendarEventNotification(String eventId) async {
    final notificationId = _getCalendarNotificationId(eventId);
    await _notifications.cancel(notificationId);

    if (kDebugMode) {
      debugPrint('🗑️ Takvim bildirimi iptal edildi: $eventId');
    }
  }

  /// Tüm takvim bildirimlerini yeniden zamanla
  Future<void> rescheduleAllCalendarNotifications(
    List<CalendarEvent> events,
  ) async {
    if (!_initialized) await initialize();

    // Önce mevcut takvim bildirimlerini iptal et
    for (final event in events) {
      await cancelCalendarEventNotification(event.id);
    }

    // Sonra hepsini yeniden zamanla
    for (final event in events) {
      if (event.hasReminder && !event.isCompleted && !event.isPast) {
        await scheduleCalendarEventNotification(event);
      }
    }
  }

  /// Takvim etkinliği için notification ID üret
  int _getCalendarNotificationId(String eventId) {
    // Calendar için farklı bir prefix kullan
    final idString = 'cal_$eventId';
    return idString.hashCode.abs() % 2147483647;
  }
}
