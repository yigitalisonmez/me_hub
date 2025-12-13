import 'package:hive/hive.dart';
import '../models/affirmation_session.dart';

/// Repository for managing affirmation sessions in Hive
class AffirmationRepository {
  static const String _boxName = 'affirmation_sessions';
  Box<AffirmationSession>? _box;

  /// Initialize the repository and open the Hive box
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(AffirmationSessionAdapter());
    }
    _box = await Hive.openBox<AffirmationSession>(_boxName);
  }

  /// Get all saved sessions
  List<AffirmationSession> getAllSessions() {
    return _box?.values.toList() ?? [];
  }

  /// Get a session by ID
  AffirmationSession? getSession(String id) {
    return _box?.values.cast<AffirmationSession?>().firstWhere(
      (s) => s?.id == id,
      orElse: () => null,
    );
  }

  /// Save a new session or update existing one
  Future<void> saveSession(AffirmationSession session) async {
    await _box?.put(session.id, session);
  }

  /// Delete a session by ID
  Future<void> deleteSession(String id) async {
    final session = getSession(id);
    if (session != null) {
      await session.delete();
    }
  }

  /// Update completed sessions count
  Future<void> incrementCompletedSessions(String id) async {
    final session = getSession(id);
    if (session != null) {
      final updated = session.copyWith(
        completedSessions: session.completedSessions + 1,
      );
      await saveSession(updated);
    }
  }

  /// Get total completed sessions across all affirmations
  int getTotalCompletedSessions() {
    return _box?.values.fold<int>(
          0,
          (sum, session) => sum + session.completedSessions,
        ) ??
        0;
  }

  /// Close the box
  Future<void> close() async {
    await _box?.close();
  }
}
