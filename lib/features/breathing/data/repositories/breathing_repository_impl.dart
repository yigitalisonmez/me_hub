import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/breathing_session.dart';
import '../../domain/entities/breathing_technique.dart';
import '../../domain/repositories/breathing_repository.dart';
import '../mappers/breathing_session_mapper.dart';
import '../mappers/breathing_technique_mapper.dart';
import '../../../../core/utils/result.dart';

/// Implementation of BreathingRepository using SharedPreferences
class BreathingRepositoryImpl implements BreathingRepository {
  static const _sessionHistoryKey = 'breathing_session_history';
  static const _customTechniquesKey = 'breathing_custom_techniques';
  static const _hapticEnabledKey = 'breathing_haptic_enabled';
  static const _bgVolumeKey = 'breathing_bg_volume';

  @override
  Future<Result<void>> saveSession(BreathingSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsResult = await getSessions();

      List<BreathingSession> sessions = [];
      if (sessionsResult.isSuccess) {
        sessions = List.from(sessionsResult.data ?? []);
      }

      sessions.insert(0, session);

      // Keep only last 50 sessions
      final toSave = sessions.take(50).toList();
      final json = jsonEncode(
        toSave.map((s) => BreathingSessionMapper.toJson(s)).toList(),
      );
      await prefs.setString(_sessionHistoryKey, json);

      return const Success(null);
    } catch (e) {
      debugPrint('Error saving breathing session: $e');
      return Error(message: e.toString());
    }
  }

  @override
  Future<Result<List<BreathingSession>>> getSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_sessionHistoryKey);

      if (json == null) return const Success([]);

      final list = jsonDecode(json) as List;
      final sessions = list
          .map(
            (e) => BreathingSessionMapper.fromJson(e as Map<String, dynamic>),
          )
          .toList();

      return Success(sessions);
    } catch (e) {
      debugPrint('Error loading breathing sessions: $e');
      return Error(message: e.toString());
    }
  }

  @override
  Future<Result<int>> getTotalMinutes() async {
    final sessionsResult = await getSessions();
    if (!sessionsResult.isSuccess) {
      return Error(message: sessionsResult.errorMessage ?? 'Unknown error');
    }

    final sessions = sessionsResult.data ?? [];
    final totalMinutes = sessions.fold<int>(
      0,
      (sum, s) => sum + (s.actualDurationSeconds ~/ 60),
    );

    return Success(totalMinutes);
  }

  @override
  Future<Result<int>> getCurrentStreak() async {
    final sessionsResult = await getSessions();
    if (!sessionsResult.isSuccess) {
      return Error(message: sessionsResult.errorMessage ?? 'Unknown error');
    }

    final sessions = sessionsResult.data ?? [];
    if (sessions.isEmpty) return const Success(0);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int streak = 0;

    // Get unique session dates
    final sessionDates =
        sessions
            .where((s) => s.isCompleted)
            .map(
              (s) => DateTime(
                s.completedAt!.year,
                s.completedAt!.month,
                s.completedAt!.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (sessionDates.isEmpty) return const Success(0);

    // Determine starting date for streak check
    DateTime checkDate;
    if (sessionDates.contains(today)) {
      checkDate = today;
    } else if (sessionDates.contains(yesterday)) {
      checkDate = yesterday;
    } else {
      return const Success(0);
    }

    // Count consecutive days backwards
    for (final date in sessionDates) {
      if (date == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (date.isBefore(checkDate)) {
        break;
      }
    }

    return Success(streak);
  }

  @override
  Future<Result<List<BreathingTechnique>>> getCustomTechniques() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_customTechniquesKey);

      if (json == null) return const Success([]);

      final list = jsonDecode(json) as List;
      final techniques = list
          .map(
            (e) => BreathingTechniqueMapper.fromJson(e as Map<String, dynamic>),
          )
          .toList();

      return Success(techniques);
    } catch (e) {
      debugPrint('Error loading custom techniques: $e');
      return Error(message: e.toString());
    }
  }

  @override
  Future<Result<void>> saveCustomTechnique(BreathingTechnique technique) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final techniquesResult = await getCustomTechniques();

      List<BreathingTechnique> techniques = [];
      if (techniquesResult.isSuccess) {
        techniques = List.from(techniquesResult.data ?? []);
      }

      techniques.add(technique);

      final json = jsonEncode(
        techniques.map((t) => BreathingTechniqueMapper.toJson(t)).toList(),
      );
      await prefs.setString(_customTechniquesKey, json);

      return const Success(null);
    } catch (e) {
      debugPrint('Error saving custom technique: $e');
      return Error(message: e.toString());
    }
  }

  @override
  Future<Result<void>> deleteCustomTechnique(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final techniquesResult = await getCustomTechniques();

      if (!techniquesResult.isSuccess) {
        return Error(message: techniquesResult.errorMessage ?? 'Unknown error');
      }

      final techniques = List<BreathingTechnique>.from(
        techniquesResult.data ?? [],
      );
      techniques.removeWhere((t) => t.id == id);

      final json = jsonEncode(
        techniques.map((t) => BreathingTechniqueMapper.toJson(t)).toList(),
      );
      await prefs.setString(_customTechniquesKey, json);

      return const Success(null);
    } catch (e) {
      debugPrint('Error deleting custom technique: $e');
      return Error(message: e.toString());
    }
  }

  @override
  Future<Result<bool>> getHapticEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Success(prefs.getBool(_hapticEnabledKey) ?? true);
    } catch (e) {
      return Error(message: e.toString());
    }
  }

  @override
  Future<Result<void>> setHapticEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticEnabledKey, enabled);
      return const Success(null);
    } catch (e) {
      return Error(message: e.toString());
    }
  }

  @override
  Future<Result<double>> getBackgroundVolume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Success(prefs.getDouble(_bgVolumeKey) ?? 0.5);
    } catch (e) {
      return Error(message: e.toString());
    }
  }

  @override
  Future<Result<void>> setBackgroundVolume(double volume) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_bgVolumeKey, volume);
      return const Success(null);
    } catch (e) {
      return Error(message: e.toString());
    }
  }

  @override
  Future<Result<void>> clearSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionHistoryKey);
      return const Success(null);
    } catch (e) {
      return Error(message: e.toString());
    }
  }
}
