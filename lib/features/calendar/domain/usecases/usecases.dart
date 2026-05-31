import '../entities/calendar_event.dart';
import '../repositories/calendar_repository.dart';

/// Tüm etkinlikleri getir
class GetAllEvents {
  final CalendarRepository repository;

  GetAllEvents(this.repository);

  Future<List<CalendarEvent>> call() => repository.getAllEvents();
}

/// Belirli bir tarihe ait etkinlikleri getir
class GetEventsByDate {
  final CalendarRepository repository;

  GetEventsByDate(this.repository);

  Future<List<CalendarEvent>> call(DateTime date) =>
      repository.getEventsByDate(date);
}

/// Belirli bir aydaki etkinlikleri getir
class GetEventsByMonth {
  final CalendarRepository repository;

  GetEventsByMonth(this.repository);

  Future<List<CalendarEvent>> call(int year, int month) =>
      repository.getEventsByMonth(year, month);
}

/// Gelecek etkinlikleri getir
class GetUpcomingEvents {
  final CalendarRepository repository;

  GetUpcomingEvents(this.repository);

  Future<List<CalendarEvent>> call() => repository.getUpcomingEvents();
}

/// Bekleyen (tamamlanmamış) etkinlikleri getir
class GetPendingEvents {
  final CalendarRepository repository;

  GetPendingEvents(this.repository);

  Future<List<CalendarEvent>> call() => repository.getPendingEvents();
}

/// Etkinlik ekle
class AddEvent {
  final CalendarRepository repository;

  AddEvent(this.repository);

  Future<void> call(CalendarEvent event) => repository.addEvent(event);
}

/// Etkinlik güncelle
class UpdateEvent {
  final CalendarRepository repository;

  UpdateEvent(this.repository);

  Future<void> call(CalendarEvent event) => repository.updateEvent(event);
}

/// Etkinlik sil
class DeleteEvent {
  final CalendarRepository repository;

  DeleteEvent(this.repository);

  Future<void> call(String eventId) => repository.deleteEvent(eventId);
}

/// ID ile etkinlik getir
class GetEventById {
  final CalendarRepository repository;

  GetEventById(this.repository);

  Future<CalendarEvent?> call(String eventId) =>
      repository.getEventById(eventId);
}
