import '../entities/gratitude_entry.dart';
import '../repositories/gratitude_repository.dart';

/// Add a new gratitude entry
class AddGratitudeEntry {
  final GratitudeRepository _repository;

  AddGratitudeEntry(this._repository);

  Future<GratitudeEntry> call(GratitudeEntry entry) async {
    return await _repository.addEntry(entry);
  }
}

/// Get today's gratitude entry
class GetTodayGratitudeEntry {
  final GratitudeRepository _repository;

  GetTodayGratitudeEntry(this._repository);

  Future<GratitudeEntry?> call({required EntryType entryType}) async {
    return await _repository.getTodayEntry(entryType: entryType);
  }
}

/// Get all gratitude entries
class GetAllGratitudeEntries {
  final GratitudeRepository _repository;

  GetAllGratitudeEntries(this._repository);

  Future<List<GratitudeEntry>> call() async {
    return await _repository.getAllEntries();
  }
}

/// Get entries in date range
class GetGratitudeEntriesInRange {
  final GratitudeRepository _repository;

  GetGratitudeEntriesInRange(this._repository);

  Future<List<GratitudeEntry>> call(DateTime start, DateTime end) async {
    return await _repository.getEntriesInRange(start, end);
  }
}

/// Get a random past entry for positive recall
class GetRandomPastGratitudeEntry {
  final GratitudeRepository _repository;

  GetRandomPastGratitudeEntry(this._repository);

  Future<GratitudeEntry?> call() async {
    return await _repository.getRandomPastEntry();
  }
}

/// Update a gratitude entry
class UpdateGratitudeEntry {
  final GratitudeRepository _repository;

  UpdateGratitudeEntry(this._repository);

  Future<GratitudeEntry> call(GratitudeEntry entry) async {
    return await _repository.updateEntry(entry);
  }
}

/// Delete a gratitude entry
class DeleteGratitudeEntry {
  final GratitudeRepository _repository;

  DeleteGratitudeEntry(this._repository);

  Future<void> call(String id) async {
    await _repository.deleteEntry(id);
  }
}

/// Get current gratitude streak
class GetGratitudeStreak {
  final GratitudeRepository _repository;

  GetGratitudeStreak(this._repository);

  Future<int> call() async {
    return await _repository.getCurrentStreak();
  }
}

/// Get emotion tag statistics
class GetEmotionTagStats {
  final GratitudeRepository _repository;

  GetEmotionTagStats(this._repository);

  Future<Map<String, int>> call() async {
    return await _repository.getEmotionTagStats();
  }
}
