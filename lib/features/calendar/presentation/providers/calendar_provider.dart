import 'package:flutter/foundation.dart';
import '../../../calendar/domain/entities/calendar_event.dart';
import '../../../calendar/domain/entities/reminder_offset.dart';
import '../../../calendar/data/datasources/calendar_local_datasource.dart';
import '../../../../core/services/notification_service.dart';

/// Takvim state management provider
class CalendarProvider extends ChangeNotifier {
  final CalendarLocalDatasource _datasource;
  final NotificationService _notificationService;

  CalendarProvider({
    required CalendarLocalDatasource datasource,
    required NotificationService notificationService,
  }) : _datasource = datasource,
       _notificationService = notificationService;

  // State
  List<CalendarEvent> _events = [];
  List<CalendarEvent> _selectedDayEvents = [];
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CalendarEvent> get events => _events;
  List<CalendarEvent> get selectedDayEvents => _selectedDayEvents;
  DateTime get selectedDate => _selectedDate;
  DateTime get focusedMonth => _focusedMonth;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Gelecek etkinlikleri getir
  List<CalendarEvent> get upcomingEvents =>
      _events.where((e) => !e.isPast && !e.isCompleted).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  /// Bugünkü etkinlik sayısı
  int get todayEventCount =>
      _events.where((e) => e.isToday && !e.isCompleted).length;

  /// Başlangıç yüklemesi
  Future<void> initialize() async {
    await loadEvents();
    await _loadSelectedDayEvents();
    await _rescheduleNotifications();
  }

  /// Tüm etkinlikleri yükle
  Future<void> loadEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _datasource.getAllEvents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Etkinlikler yüklenirken hata: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Seçili güne ait etkinlikleri yükle
  Future<void> _loadSelectedDayEvents() async {
    _selectedDayEvents = await _datasource.getEventsByDate(_selectedDate);
    notifyListeners();
  }

  /// Seçili tarihi değiştir
  Future<void> selectDate(DateTime date) async {
    _selectedDate = date;
    await _loadSelectedDayEvents();
  }

  /// Odaklanan ayı değiştir
  void setFocusedMonth(DateTime month) {
    _focusedMonth = month;
    notifyListeners();
  }

  /// Önceki aya git
  void goToPreviousMonth() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    notifyListeners();
  }

  /// Sonraki aya git
  void goToNextMonth() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    notifyListeners();
  }

  /// Bugüne git
  Future<void> goToToday() async {
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    await selectDate(now);
  }

  /// Yeni etkinlik ekle
  Future<bool> addEvent({
    required String title,
    String? description,
    required DateTime dateTime,
    required ReminderOffset reminderOffset,
    bool hasReminder = true,
    String? categoryId,
  }) async {
    try {
      final event = CalendarEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        dateTime: dateTime,
        reminderOffset: CalendarEvent.toHiveOffset(reminderOffset),
        createdAt: DateTime.now(),
        hasReminder: hasReminder,
        categoryId: categoryId,
      );

      await _datasource.addEvent(event);

      // Bildirim zamanla
      if (hasReminder) {
        await _notificationService.scheduleCalendarEventNotification(event);
      }

      await loadEvents();
      await _loadSelectedDayEvents();

      if (kDebugMode) {
        debugPrint('✅ Etkinlik eklendi: $title');
      }

      return true;
    } catch (e) {
      _error = 'Etkinlik eklenirken hata: $e';
      notifyListeners();
      return false;
    }
  }

  /// Etkinliği güncelle
  Future<bool> updateEvent(CalendarEvent event) async {
    try {
      await _datasource.updateEvent(event);

      // Bildirimi güncelle
      await _notificationService.cancelCalendarEventNotification(event.id);
      if (event.hasReminder && !event.isCompleted && !event.isPast) {
        await _notificationService.scheduleCalendarEventNotification(event);
      }

      await loadEvents();
      await _loadSelectedDayEvents();

      return true;
    } catch (e) {
      _error = 'Etkinlik güncellenirken hata: $e';
      notifyListeners();
      return false;
    }
  }

  /// Etkinliği sil
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _datasource.deleteEvent(eventId);
      await _notificationService.cancelCalendarEventNotification(eventId);

      await loadEvents();
      await _loadSelectedDayEvents();

      if (kDebugMode) {
        debugPrint('🗑️ Etkinlik silindi: $eventId');
      }

      return true;
    } catch (e) {
      _error = 'Etkinlik silinirken hata: $e';
      notifyListeners();
      return false;
    }
  }

  /// Etkinliği tamamlandı olarak işaretle
  Future<bool> toggleEventCompletion(CalendarEvent event) async {
    final updatedEvent = event.isCompleted
        ? event.markAsIncomplete()
        : event.markAsCompleted();

    return updateEvent(updatedEvent);
  }

  /// Belirli bir günde etkinlik var mı?
  bool hasEventsOnDay(DateTime day) {
    return _events.any(
      (event) =>
          event.dateTime.year == day.year &&
          event.dateTime.month == day.month &&
          event.dateTime.day == day.day &&
          !event.isCompleted,
    );
  }

  /// Belirli bir gündeki etkinlik sayısı
  int eventCountOnDay(DateTime day) {
    return _events
        .where(
          (event) =>
              event.dateTime.year == day.year &&
              event.dateTime.month == day.month &&
              event.dateTime.day == day.day &&
              !event.isCompleted,
        )
        .length;
  }

  /// Tüm bildirimleri yeniden zamanla
  Future<void> _rescheduleNotifications() async {
    try {
      await _notificationService.rescheduleAllCalendarNotifications(_events);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Bildirim zamanlama hatası: $e');
      }
    }
  }

  /// Hatayı temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
