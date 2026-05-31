import '../entities/calendar_event.dart';

/// Takvim repository interface
abstract class CalendarRepository {
  /// Tüm etkinlikleri getir
  Future<List<CalendarEvent>> getAllEvents();

  /// Belirli bir tarihe ait etkinlikleri getir
  Future<List<CalendarEvent>> getEventsByDate(DateTime date);

  /// Belirli bir ay içindeki etkinlikleri getir
  Future<List<CalendarEvent>> getEventsByMonth(int year, int month);

  /// Gelecek etkinlikleri getir
  Future<List<CalendarEvent>> getUpcomingEvents();

  /// Etkinlik ekle
  Future<void> addEvent(CalendarEvent event);

  /// Etkinlik güncelle
  Future<void> updateEvent(CalendarEvent event);

  /// Etkinlik sil
  Future<void> deleteEvent(String eventId);

  /// ID ile etkinlik getir
  Future<CalendarEvent?> getEventById(String eventId);

  /// Tamamlanmamış etkinlikleri getir
  Future<List<CalendarEvent>> getPendingEvents();
}
