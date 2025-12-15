import '../../domain/entities/gratitude_entry.dart';
import '../../domain/repositories/gratitude_repository.dart';
import '../datasources/gratitude_local_datasource.dart';

/// Implementation of GratitudeRepository using local Hive storage
class GratitudeRepositoryImpl implements GratitudeRepository {
  final GratitudeLocalDataSource _localDataSource;

  GratitudeRepositoryImpl(this._localDataSource);

  @override
  Future<List<GratitudeEntry>> getAllEntries() async {
    return await _localDataSource.getAllEntries();
  }

  @override
  Future<GratitudeEntry?> getTodayEntry({required EntryType entryType}) async {
    return await _localDataSource.getEntryByDateAndType(
      DateTime.now(),
      entryType,
    );
  }

  @override
  Future<GratitudeEntry?> getEntryByDate(
    DateTime date, {
    required EntryType entryType,
  }) async {
    return await _localDataSource.getEntryByDateAndType(date, entryType);
  }

  @override
  Future<List<GratitudeEntry>> getEntriesInRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _localDataSource.getEntriesInRange(start, end);
  }

  @override
  Future<GratitudeEntry> addEntry(GratitudeEntry entry) async {
    return await _localDataSource.saveEntry(entry);
  }

  @override
  Future<GratitudeEntry> updateEntry(GratitudeEntry entry) async {
    return await _localDataSource.saveEntry(entry);
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _localDataSource.deleteEntry(id);
  }

  @override
  Future<GratitudeEntry?> getRandomPastEntry() async {
    return await _localDataSource.getRandomPastEntry();
  }

  @override
  Future<int> getTotalEntriesCount() async {
    return await _localDataSource.getTotalCount();
  }

  @override
  Future<int> getCurrentStreak() async {
    return await _localDataSource.calculateStreak();
  }

  @override
  Future<Map<String, int>> getEmotionTagStats() async {
    return await _localDataSource.getEmotionTagStats();
  }

  @override
  Future<List<GratitudeEntry>> getEntriesByEmotionTag(String tag) async {
    final allEntries = await _localDataSource.getAllEntries();
    return allEntries
        .where((entry) => entry.allEmotionTags.contains(tag))
        .toList();
  }
}
