import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/calendar_event.dart';

/// Takvim etkinlikleri local datasource
class CalendarLocalDatasource {
  static const String _boxName = 'calendar_events';

  Box<CalendarEvent>? _box;

  /// Box'ı aç
  Future<Box<CalendarEvent>> get box async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox<CalendarEvent>(_boxName);
    return _box!;
  }

  /// Tüm etkinlikleri getir
  Future<List<CalendarEvent>> getAllEvents() async {
    final openedBox = await box;
    return openedBox.values.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Belirli bir tarihe ait etkinlikleri getir
  Future<List<CalendarEvent>> getEventsByDate(DateTime date) async {
    final openedBox = await box;

    // Normalize to start of day for comparison
    final queryYear = date.year;
    final queryMonth = date.month;
    final queryDay = date.day;

    return openedBox.values
        .where(
          (event) =>
              event.dateTime.year == queryYear &&
              event.dateTime.month == queryMonth &&
              event.dateTime.day == queryDay,
        )
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Belirli bir ay içindeki etkinlikleri getir
  Future<List<CalendarEvent>> getEventsByMonth(int year, int month) async {
    final openedBox = await box;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    return openedBox.values
        .where(
          (event) =>
              event.dateTime.isAfter(
                startOfMonth.subtract(const Duration(seconds: 1)),
              ) &&
              event.dateTime.isBefore(endOfMonth),
        )
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Gelecek etkinlikleri getir
  Future<List<CalendarEvent>> getUpcomingEvents() async {
    final openedBox = await box;
    final now = DateTime.now();

    return openedBox.values
        .where((event) => event.dateTime.isAfter(now) && !event.isCompleted)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Bekleyen (tamamlanmamış) etkinlikleri getir
  Future<List<CalendarEvent>> getPendingEvents() async {
    final openedBox = await box;

    return openedBox.values.where((event) => !event.isCompleted).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Etkinlik ekle
  Future<void> addEvent(CalendarEvent event) async {
    final openedBox = await box;
    await openedBox.put(event.id, event);
  }

  /// Etkinlik güncelle
  Future<void> updateEvent(CalendarEvent event) async {
    final openedBox = await box;
    await openedBox.put(event.id, event);
  }

  /// Etkinlik sil
  Future<void> deleteEvent(String eventId) async {
    final openedBox = await box;
    await openedBox.delete(eventId);
  }

  /// ID ile etkinlik getir
  Future<CalendarEvent?> getEventById(String eventId) async {
    final openedBox = await box;
    return openedBox.get(eventId);
  }

  /// Etkinlik sayısını getir
  Future<int> getEventCount() async {
    final openedBox = await box;
    return openedBox.length;
  }

  /// Bugün için etkinlik sayısını getir
  Future<int> getTodayEventCount() async {
    final events = await getEventsByDate(DateTime.now());
    return events.where((e) => !e.isCompleted).length;
  }
}
