import '../entities/breathing_session.dart';
import '../entities/breathing_technique.dart';
import '../../../../core/utils/result.dart';

/// Breathing repository interface
/// Defines the contract for breathing-related data operations
abstract class BreathingRepository {
  /// Save a completed breathing session
  Future<Result<void>> saveSession(BreathingSession session);

  /// Get all breathing sessions
  Future<Result<List<BreathingSession>>> getSessions();

  /// Get total mindful minutes across all sessions
  Future<Result<int>> getTotalMinutes();

  /// Get current streak (consecutive days with sessions)
  Future<Result<int>> getCurrentStreak();

  /// Get custom breathing techniques
  Future<Result<List<BreathingTechnique>>> getCustomTechniques();

  /// Save a custom breathing technique
  Future<Result<void>> saveCustomTechnique(BreathingTechnique technique);

  /// Delete a custom breathing technique
  Future<Result<void>> deleteCustomTechnique(String id);

  /// Get haptic enabled setting
  Future<Result<bool>> getHapticEnabled();

  /// Set haptic enabled setting
  Future<Result<void>> setHapticEnabled(bool enabled);

  /// Get background volume setting
  Future<Result<double>> getBackgroundVolume();

  /// Set background volume setting
  Future<Result<void>> setBackgroundVolume(double volume);

  /// Clear all session history
  Future<Result<void>> clearSessions();
}
