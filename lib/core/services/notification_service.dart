import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../features/routines/domain/entities/routine.dart';

// flutter_native_timezone paketi KALDIRILDI - gereksiz!

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  tz.Location? _localLocation;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    // Türkiye timezone'u direkt kullan - daha basit ve güvenilir
    _localLocation = tz.getLocation('Europe/Istanbul');
    tz.setLocalLocation(_localLocation!);

    if (kDebugMode) {
      debugPrint('✅ Timezone ayarlandı: Europe/Istanbul');
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

    debugPrint('🔄 Tüm bildirimleri yeniden zamanlama başlıyor...');

    await cancelAllNotifications();
    debugPrint('✅ Tüm bildirimler iptal edildi');

    int scheduledCount = 0;
    for (final routine in routines) {
      if (routine.time != null) {
        await scheduleRoutineNotifications(routine);
        scheduledCount++;
      }
    }

    debugPrint('✅ Toplam $scheduledCount rutin için bildirimler zamanlandı');
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

      if (kDebugMode) {
        final timeUntilNotification = scheduledDate.difference(now);
        debugPrint('✅ ${routine.name} - ${_getDayName(dayIndex)}');
        debugPrint(
          '   🕐 Rutin saati: ${routineHour.toString().padLeft(2, '0')}:${routineMinute.toString().padLeft(2, '0')}',
        );
        debugPrint(
          '   🔔 Bildirim saati: ${notificationHour.toString().padLeft(2, '0')}:${notificationMinute.toString().padLeft(2, '0')}',
        );
        debugPrint(
          '   📅 İlk bildirim: ${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year} ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}',
        );
        debugPrint(
          '   ⏳ Kalan süre: ${timeUntilNotification.inMinutes} dakika',
        );
        debugPrint('   🆔 ID: $notificationId');
      }

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
        '$randomQuote',
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

  String _getDayName(int dayIndex) {
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return days[dayIndex];
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

  Future<void> checkPendingNotifications() async {
    if (!_initialized) await initialize();

    final pendingNotifications = await _notifications
        .pendingNotificationRequests();
    debugPrint(
      '📋 Zamanlanmış bildirim sayısı: ${pendingNotifications.length}',
    );

    if (pendingNotifications.isEmpty) {
      debugPrint('⚠️ Hiç zamanlanmış bildirim yok!');
    } else {
      for (final notification in pendingNotifications) {
        debugPrint(
          '   - ID: ${notification.id}, Başlık: ${notification.title}',
        );
      }
    }
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
}
