import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../affirmations/data/models/background_sound.dart';
import '../../data/models/breathing_technique.dart';
import '../../data/models/breathing_session.dart';

/// Breathing phase during a session
enum BreathingPhase { inhale, holdIn, exhale, holdOut }

/// Session flow states
enum SessionState {
  idle,
  moodCheckBefore,
  preparing,
  breathing,
  moodCheckAfter,
  complete,
}

/// Provider for managing breathing exercise state
class BreathingProvider extends ChangeNotifier {
  // Audio player for background sounds
  final AudioPlayer _backgroundPlayer = AudioPlayer();

  // Selected technique
  BreathingTechnique? _selectedTechnique;

  // Session state
  SessionState _sessionState = SessionState.idle;
  BreathingPhase _currentPhase = BreathingPhase.inhale;

  // Timing
  int _phaseSecondsRemaining = 0;
  int _totalSecondsRemaining = 0;
  int _targetDurationMinutes = 3;
  int _cyclesCompleted = 0;
  int _sessionStartTime = 0;
  int _phaseStartTime = 0; // Timestamp when current phase started

  // Animation progress (0.0 to 1.0 within current phase)
  double _phaseProgress = 0.0;

  // Mood tracking
  int? _moodBefore;
  int? _moodAfter;

  // Settings
  bool _hapticEnabled = true;
  BackgroundSound? _selectedBackground;
  double _backgroundVolume = 0.5;

  // Session history
  List<BreathingSession> _sessionHistory = [];

  // Custom techniques
  List<BreathingTechnique> _customTechniques = [];

  // Timer
  Timer? _breathingTimer;
  Timer? _phaseTimer;
  Timer? _hapticTimer;

  // Quick mode (SOS button - skip mood check)
  bool _isQuickMode = false;

  // Getters
  BreathingTechnique? get selectedTechnique => _selectedTechnique;
  SessionState get sessionState => _sessionState;
  BreathingPhase get currentPhase => _currentPhase;
  int get phaseSecondsRemaining => _phaseSecondsRemaining;
  int get totalSecondsRemaining => _totalSecondsRemaining;
  int get targetDurationMinutes => _targetDurationMinutes;
  int get cyclesCompleted => _cyclesCompleted;
  double get phaseProgress => _phaseProgress;
  int? get moodBefore => _moodBefore;
  int? get moodAfter => _moodAfter;
  bool get hapticEnabled => _hapticEnabled;
  BackgroundSound? get selectedBackground => _selectedBackground;
  double get backgroundVolume => _backgroundVolume;
  List<BreathingSession> get sessionHistory => _sessionHistory;
  List<BreathingTechnique> get customTechniques => _customTechniques;
  bool get isQuickMode => _isQuickMode;

  /// All available techniques (presets + custom)
  List<BreathingTechnique> get allTechniques => [
    ...BreathingTechnique.presets,
    ..._customTechniques,
  ];

  /// Available background sounds (from affirmations)
  List<BackgroundSound> get availableBackgrounds => BackgroundSound.presets;

  /// Current phase label in English
  String get phaseLabel {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return 'Breathe In';
      case BreathingPhase.holdIn:
        return 'Hold';
      case BreathingPhase.exhale:
        return 'Breathe Out';
      case BreathingPhase.holdOut:
        return 'Hold';
    }
  }

  /// Total progress through the session (0.0 to 1.0)
  double get sessionProgress {
    final totalSeconds = _targetDurationMinutes * 60;
    if (totalSeconds == 0) return 0.0;
    final elapsed = totalSeconds - _totalSecondsRemaining;
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  /// Formatted remaining time
  String get formattedRemainingTime {
    final minutes = _totalSecondsRemaining ~/ 60;
    final seconds = _totalSecondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Total mindful minutes across all sessions
  int get totalMindfulMinutes {
    return _sessionHistory.fold<int>(
      0,
      (sum, s) => sum + (s.actualDurationSeconds ~/ 60),
    );
  }

  /// Current streak (consecutive days with sessions)
  /// Does not break streak if user hasn't done exercise today yet
  int get currentStreak {
    if (_sessionHistory.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int streak = 0;

    // Get unique session dates
    final sessionDates =
        _sessionHistory
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

    if (sessionDates.isEmpty) return 0;

    // Determine starting date for streak check
    // If there's a session today, start from today
    // If no session today but there's one yesterday, start from yesterday
    DateTime checkDate;
    if (sessionDates.contains(today)) {
      checkDate = today;
    } else if (sessionDates.contains(yesterday)) {
      // User hasn't done exercise today yet, but did yesterday
      // Start counting from yesterday (streak is still active)
      checkDate = yesterday;
    } else {
      // No session today or yesterday, streak is broken
      return 0;
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

    return streak;
  }

  // ==================== Initialization ====================

  Future<void> init() async {
    await _loadSessionHistory();
    await _loadCustomTechniques();
    await _loadSettings();

    // Set default background
    if (BackgroundSound.presets.isNotEmpty) {
      _selectedBackground = BackgroundSound.presets.first;
    }

    notifyListeners();
  }

  // ==================== Technique Selection ====================

  void selectTechnique(BreathingTechnique technique) {
    _selectedTechnique = technique;
    notifyListeners();
  }

  void setDuration(int minutes) {
    _targetDurationMinutes = minutes.clamp(1, 60);
    notifyListeners();
  }

  // ==================== Session Flow ====================

  /// Start a normal session with mood check
  void startSession() {
    if (_selectedTechnique == null) return;

    _isQuickMode = false;
    _sessionState = SessionState.moodCheckBefore;
    _moodBefore = null;
    _moodAfter = null;
    notifyListeners();
  }

  /// Start quick session (SOS mode) - skip mood check, use 4-7-8
  void startQuickSession() {
    _selectedTechnique = BreathingTechnique.findById('4-7-8');
    _targetDurationMinutes = 3;
    _isQuickMode = true;
    _moodBefore = null;
    _moodAfter = null;
    _startBreathing();
  }

  /// Set mood before session and proceed
  void setMoodBefore(int mood) {
    _moodBefore = mood.clamp(1, 5);
    _sessionState = SessionState.preparing;
    notifyListeners();

    // 3 second preparation countdown
    Future.delayed(const Duration(seconds: 3), () {
      if (_sessionState == SessionState.preparing) {
        _startBreathing();
      }
    });
  }

  /// Set mood after session
  void setMoodAfter(int mood) {
    _moodAfter = mood.clamp(1, 5);
    _completeSession();
  }

  /// Skip mood check after (for quick exits)
  void skipMoodAfter() {
    _completeSession();
  }

  void _startBreathing() {
    if (_selectedTechnique == null) return;

    _sessionState = SessionState.breathing;
    _totalSecondsRemaining = _targetDurationMinutes * 60;
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    _cyclesCompleted = 0;
    _currentPhase = BreathingPhase.inhale;
    _phaseSecondsRemaining = _selectedTechnique!.inhaleSeconds;
    _phaseStartTime = DateTime.now().millisecondsSinceEpoch;
    _phaseProgress = 0.0;

    // Start background audio
    if (_selectedBackground != null) {
      _startBackgroundAudio();
    }

    // Start haptic loop
    if (_hapticEnabled) {
      _startHapticLoop(BreathingPhase.inhale);
    }

    // Start timers
    _startTimers();

    notifyListeners();
  }

  void _startTimers() {
    // Main countdown timer (1 second ticks)
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_totalSecondsRemaining > 0) {
        _totalSecondsRemaining--;
        _phaseSecondsRemaining--;

        if (_phaseSecondsRemaining <= 0) {
          _advancePhase();
        }

        notifyListeners();
      } else {
        _onSessionTimerComplete();
      }
    });

    // Smooth animation timer (60fps)
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updatePhaseProgress();
    });
  }

  void _updatePhaseProgress() {
    if (_selectedTechnique == null) return;

    final phaseDuration = _getCurrentPhaseDuration();
    if (phaseDuration == 0) {
      _phaseProgress = 1.0;
      return;
    }

    // Calculate continuous progress using real elapsed time
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = now - _phaseStartTime;
    final phaseDurationMs = phaseDuration * 1000;

    _phaseProgress = (elapsedMs / phaseDurationMs).clamp(0.0, 1.0);

    notifyListeners();
  }

  int _getCurrentPhaseDuration() {
    if (_selectedTechnique == null) return 0;

    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return _selectedTechnique!.inhaleSeconds;
      case BreathingPhase.holdIn:
        return _selectedTechnique!.holdAfterInhaleSeconds;
      case BreathingPhase.exhale:
        return _selectedTechnique!.exhaleSeconds;
      case BreathingPhase.holdOut:
        return _selectedTechnique!.holdAfterExhaleSeconds;
    }
  }

  void _advancePhase() {
    if (_selectedTechnique == null) return;

    BreathingPhase nextPhase;
    int nextDuration;

    // Determine next phase
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        if (_selectedTechnique!.holdAfterInhaleSeconds > 0) {
          nextPhase = BreathingPhase.holdIn;
          nextDuration = _selectedTechnique!.holdAfterInhaleSeconds;
        } else {
          nextPhase = BreathingPhase.exhale;
          nextDuration = _selectedTechnique!.exhaleSeconds;
        }
        break;

      case BreathingPhase.holdIn:
        nextPhase = BreathingPhase.exhale;
        nextDuration = _selectedTechnique!.exhaleSeconds;
        break;

      case BreathingPhase.exhale:
        if (_selectedTechnique!.holdAfterExhaleSeconds > 0) {
          nextPhase = BreathingPhase.holdOut;
          nextDuration = _selectedTechnique!.holdAfterExhaleSeconds;
        } else {
          // Cycle complete, back to inhale
          _cyclesCompleted++;
          nextPhase = BreathingPhase.inhale;
          nextDuration = _selectedTechnique!.inhaleSeconds;
        }
        break;

      case BreathingPhase.holdOut:
        // Cycle complete, back to inhale
        _cyclesCompleted++;
        nextPhase = BreathingPhase.inhale;
        nextDuration = _selectedTechnique!.inhaleSeconds;
        break;
    }

    // Apple changes
    _currentPhase = nextPhase;
    _phaseSecondsRemaining = nextDuration;

    // Start haptic loop for new phase
    if (_hapticEnabled) {
      _startHapticLoop(nextPhase);
    }

    _phaseProgress = 0.0;
    _phaseStartTime = DateTime.now().millisecondsSinceEpoch;
  }

  void _startHapticLoop(BreathingPhase phase) {
    _hapticTimer?.cancel();

    if (!_hapticEnabled) return;

    switch (phase) {
      case BreathingPhase.inhale:
        // Continuous vibration for inhale (stronger)
        _hapticTimer = Timer.periodic(const Duration(milliseconds: 100), (
          timer,
        ) {
          HapticFeedback.lightImpact(); // lightImpact feels better when looped rapidly
        });
        break;

      case BreathingPhase.exhale:
        // Continuous vibration for exhale (lighter/slower)
        _hapticTimer = Timer.periodic(const Duration(milliseconds: 200), (
          timer,
        ) {
          HapticFeedback.selectionClick(); // very subtle
        });
        break;

      case BreathingPhase.holdIn:
      case BreathingPhase.holdOut:
        // Stop vibration during holds
        _hapticTimer?.cancel();
        break;
    }
  }

  void _onSessionTimerComplete() {
    _stopTimers();
    _stopBackgroundAudio();

    if (_isQuickMode) {
      _completeSession();
    } else {
      _sessionState = SessionState.moodCheckAfter;
      notifyListeners();
    }
  }

  void _completeSession() {
    final actualDuration =
        (DateTime.now().millisecondsSinceEpoch - _sessionStartTime) ~/ 1000;

    final session = BreathingSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: DateTime.fromMillisecondsSinceEpoch(_sessionStartTime),
      completedAt: DateTime.now(),
      techniqueId: _selectedTechnique!.id,
      techniqueName: _selectedTechnique!.name,
      targetDurationMinutes: _targetDurationMinutes,
      actualDurationSeconds: actualDuration,
      moodBefore: _moodBefore,
      moodAfter: _moodAfter,
      cyclesCompleted: _cyclesCompleted,
    );

    _sessionHistory.insert(0, session);
    _saveSessionHistory();

    _sessionState = SessionState.complete;
    notifyListeners();
  }

  /// Stop current session early
  void stopSession() {
    _stopTimers();
    _stopBackgroundAudio();
    _sessionState = SessionState.idle;
    notifyListeners();
  }

  /// Reset to idle state
  void reset() {
    _stopTimers();
    _stopBackgroundAudio();
    _sessionState = SessionState.idle;
    _selectedTechnique = null;
    _moodBefore = null;
    _moodAfter = null;
    _cyclesCompleted = 0;
    notifyListeners();
  }

  void _stopTimers() {
    _breathingTimer?.cancel();
    _breathingTimer = null;
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _hapticTimer?.cancel();
    _hapticTimer = null;
  }

  // ==================== Audio ====================

  Future<void> _startBackgroundAudio() async {
    if (_selectedBackground == null) return;

    try {
      await _backgroundPlayer.setAsset(_selectedBackground!.assetPath);
      await _backgroundPlayer.setLoopMode(LoopMode.all);
      await _backgroundPlayer.setVolume(_backgroundVolume);
      _backgroundPlayer.play();
    } catch (e) {
      debugPrint('Error starting background audio: $e');
    }
  }

  Future<void> _stopBackgroundAudio() async {
    try {
      // Fade out
      for (int i = 10; i >= 0; i--) {
        await _backgroundPlayer.setVolume(_backgroundVolume * (i / 10));
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await _backgroundPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping background audio: $e');
    }
  }

  void setBackground(BackgroundSound? sound) {
    _selectedBackground = sound;

    // If we are currently breathing, update the audio immediately
    if (_sessionState == SessionState.breathing) {
      if (sound != null) {
        _startBackgroundAudio();
      } else {
        _stopBackgroundAudio();
      }
    }

    notifyListeners();
  }

  void setBackgroundVolume(double volume) {
    _backgroundVolume = volume.clamp(0.0, 1.0);
    _backgroundPlayer.setVolume(_backgroundVolume);
    notifyListeners();
  }

  void setHapticEnabled(bool enabled) {
    _hapticEnabled = enabled;
    _saveSettings();

    // Reset any existing haptic timer
    _hapticTimer?.cancel();

    if (_hapticEnabled && _sessionState == SessionState.breathing) {
      // Immediate feedback to show it's enabled
      HapticFeedback.lightImpact();
      // Start the loop for the current phase
      _startHapticLoop(_currentPhase);
    }

    notifyListeners();
  }

  // ==================== Custom Techniques ====================

  void addCustomTechnique(BreathingTechnique technique) {
    _customTechniques.add(technique);
    _saveCustomTechniques();
    notifyListeners();
  }

  void removeCustomTechnique(String id) {
    _customTechniques.removeWhere((t) => t.id == id);
    _saveCustomTechniques();
    notifyListeners();
  }

  // ==================== Persistence ====================

  Future<void> _loadSessionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('breathing_session_history');
      if (json != null) {
        final list = jsonDecode(json) as List;
        _sessionHistory = list
            .map((e) => BreathingSession.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading breathing session history: $e');
    }
  }

  Future<void> _saveSessionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep only last 50 sessions
      final toSave = _sessionHistory.take(50).toList();
      final json = jsonEncode(toSave.map((e) => e.toJson()).toList());
      await prefs.setString('breathing_session_history', json);
    } catch (e) {
      debugPrint('Error saving breathing session history: $e');
    }
  }

  Future<void> _loadCustomTechniques() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('breathing_custom_techniques');
      if (json != null) {
        final list = jsonDecode(json) as List;
        _customTechniques = list
            .map((e) => BreathingTechnique.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading custom techniques: $e');
    }
  }

  Future<void> _saveCustomTechniques() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(
        _customTechniques.map((e) => e.toJson()).toList(),
      );
      await prefs.setString('breathing_custom_techniques', json);
    } catch (e) {
      debugPrint('Error saving custom techniques: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hapticEnabled = prefs.getBool('breathing_haptic_enabled') ?? true;
      _backgroundVolume = prefs.getDouble('breathing_bg_volume') ?? 0.5;
    } catch (e) {
      debugPrint('Error loading breathing settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('breathing_haptic_enabled', _hapticEnabled);
      await prefs.setDouble('breathing_bg_volume', _backgroundVolume);
    } catch (e) {
      debugPrint('Error saving breathing settings: $e');
    }
  }

  @override
  void dispose() {
    _stopTimers();
    _backgroundPlayer.dispose();
    super.dispose();
  }
}
