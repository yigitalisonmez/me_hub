import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_local_datasource.dart';

/// CalendarRepository implementasyonu
class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarLocalDatasource _datasource;

  CalendarRepositoryImpl(this._datasource);

  @override
  Future<List<CalendarEvent>> getAllEvents() => _datasource.getAllEvents();

  @override
  Future<List<CalendarEvent>> getEventsByDate(DateTime date) =>
      _datasource.getEventsByDate(date);

  @override
  Future<List<CalendarEvent>> getEventsByMonth(int year, int month) =>
      _datasource.getEventsByMonth(year, month);

  @override
  Future<List<CalendarEvent>> getUpcomingEvents() =>
      _datasource.getUpcomingEvents();

  @override
  Future<List<CalendarEvent>> getPendingEvents() =>
      _datasource.getPendingEvents();

  @override
  Future<void> addEvent(CalendarEvent event) => _datasource.addEvent(event);

  @override
  Future<void> updateEvent(CalendarEvent event) =>
      _datasource.updateEvent(event);

  @override
  Future<void> deleteEvent(String eventId) => _datasource.deleteEvent(eventId);

  @override
  Future<CalendarEvent?> getEventById(String eventId) =>
      _datasource.getEventById(eventId);
}
