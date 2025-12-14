import '../entities/affirmation_session.dart';
import '../entities/recording.dart';
import '../../../../core/utils/result.dart';

/// Affirmation repository interface
/// Defines the contract for affirmation-related data operations
abstract class AffirmationRepository {
  // Session operations
  /// Save an affirmation session configuration
  Future<Result<void>> saveSession(AffirmationSession session);

  /// Get all saved sessions
  Future<Result<List<AffirmationSession>>> getSessions();

  /// Delete a session
  Future<Result<void>> deleteSession(String id);

  /// Update session completed count
  Future<Result<void>> incrementSessionCount(String id);

  // Recording operations
  /// Get all saved recordings
  Future<Result<List<SavedRecording>>> getRecordings();

  /// Save a new recording
  Future<Result<void>> saveRecording(SavedRecording recording);

  /// Delete a recording
  Future<Result<void>> deleteRecording(String id);

  // Session log operations
  /// Get session history logs
  Future<Result<List<SessionLog>>> getSessionLogs();

  /// Log a completed session
  Future<Result<void>> logSession(SessionLog log);

  // Statistics
  /// Get total mindful minutes
  Future<Result<int>> getTotalMinutes();

  /// Get current streak
  Future<Result<int>> getCurrentStreak();

  /// Get total completed sessions count
  Future<Result<int>> getTotalSessions();
}
