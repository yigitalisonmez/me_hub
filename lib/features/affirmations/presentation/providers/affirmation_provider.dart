import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/background_sound.dart';
import '../../data/models/recording_models.dart';

enum RecordingState { idle, recording, paused, recorded }

enum PlaybackState { idle, playing, paused }

/// Provider for managing 3-step affirmation flow
class AffirmationProvider extends ChangeNotifier {
  // Audio players
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _previewPlayer = AudioPlayer();

  // Step navigation (0=welcome, 1=record, 2=session)
  int _currentStep = 0;

  // Recording state
  RecordingState _recordingState = RecordingState.idle;
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  static const int maxRecordingSeconds = 60;

  // Saved recordings (max 3)
  List<SavedRecording> _savedRecordings = [];
  int? _selectedRecordingIndex;
  int? _previewingRecordingIndex;

  // Session history
  List<SessionLog> _sessionHistory = [];

  // Playback state
  PlaybackState _playbackState = PlaybackState.idle;
  BackgroundSound? _selectedBackground;

  // Timer state
  Duration _remainingDuration = const Duration(minutes: 30);
  Duration _totalDuration = const Duration(minutes: 30);
  Timer? _playbackTimer;

  // Volume controls
  double _voiceVolume = 1.0;
  double _backgroundVolume = 0.5;

  // Getters
  int get currentStep => _currentStep;
  RecordingState get recordingState => _recordingState;
  String? get currentRecordingPath => _currentRecordingPath;
  Duration get recordingDuration => _recordingDuration;

  List<SavedRecording> get savedRecordings => _savedRecordings;
  int? get selectedRecordingIndex => _selectedRecordingIndex;
  int? get previewingRecordingIndex => _previewingRecordingIndex;

  List<SessionLog> get sessionHistory => _sessionHistory;

  PlaybackState get playbackState => _playbackState;
  BackgroundSound? get selectedBackground => _selectedBackground;
  List<BackgroundSound> get availableBackgrounds => BackgroundSound.presets;

  Duration get remainingDuration => _remainingDuration;
  Duration get totalDuration => _totalDuration;

  double get voiceVolume => _voiceVolume;
  double get backgroundVolume => _backgroundVolume;

  AudioPlayer get previewPlayer => _previewPlayer;

  // Compatibility getters for background picker and session complete
  String? get previewingSoundId => _previewingSoundId;

  int get totalCompletedSessions => _sessionHistory.length;

  double get progress {
    if (_totalDuration.inSeconds == 0) return 0;
    return 1 - (_remainingDuration.inSeconds / _totalDuration.inSeconds);
  }

  String get formattedRemainingTime {
    final minutes = _remainingDuration.inMinutes;
    final seconds = _remainingDuration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedRecordingTime {
    final minutes = _recordingDuration.inMinutes;
    final seconds = _recordingDuration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ==================== Initialization ====================

  Future<void> init() async {
    await _loadSavedRecordings();
    await _loadSessionHistory();

    // Set default background
    if (BackgroundSound.presets.isNotEmpty) {
      _selectedBackground = BackgroundSound.presets.first;
    }

    // Listen to player states
    _previewPlayer.playerStateStream.listen(_onPreviewPlayerStateChanged);

    // Listen to voice player for manual loop with pause
    _voicePlayer.playerStateStream.listen(_onVoicePlayerStateChanged);

    notifyListeners();
  }

  void _onPreviewPlayerStateChanged(PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      _previewingRecordingIndex = null;
      notifyListeners();
    }
  }

  /// Manual loop with 4-second pause between repeats
  void _onVoicePlayerStateChanged(PlayerState state) async {
    if (state.processingState == ProcessingState.completed &&
        _playbackState == PlaybackState.playing) {
      // Wait 4 seconds before replaying
      await Future.delayed(const Duration(seconds: 4));

      // Check if still playing (user might have stopped)
      if (_playbackState == PlaybackState.playing) {
        await _voicePlayer.seek(Duration.zero);
        _voicePlayer.play();
      }
    }
  }

  // ==================== Step Navigation ====================

  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  // ==================== Recording ====================

  Future<bool> hasRecordingPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (_savedRecordings.length >= 3) return; // Max 3 recordings

    try {
      if (!await hasRecordingPermission()) return;

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/affirmation_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _recordingState = RecordingState.recording;
      _recordingDuration = Duration.zero;

      // Timer with 60 second limit
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration += const Duration(seconds: 1);
        if (_recordingDuration.inSeconds >= maxRecordingSeconds) {
          stopRecording();
        } else {
          notifyListeners();
        }
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _recordingTimer?.cancel();
      _recordingTimer = null;

      if (path != null) {
        _currentRecordingPath = path;
        _recordingState = RecordingState.recorded;
      } else {
        _recordingState = RecordingState.idle;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  /// Pause recording - can resume later
  Future<void> pauseRecording() async {
    if (_recordingState != RecordingState.recording) return;

    try {
      await _recorder.pause();
      _recordingTimer?.cancel();
      _recordingState = RecordingState.paused;
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing recording: $e');
    }
  }

  /// Resume recording from where it was paused
  Future<void> resumeRecording() async {
    if (_recordingState != RecordingState.paused) return;

    try {
      await _recorder.resume();
      _recordingState = RecordingState.recording;

      // Resume timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration += const Duration(seconds: 1);
        if (_recordingDuration.inSeconds >= maxRecordingSeconds) {
          stopRecording();
        } else {
          notifyListeners();
        }
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error resuming recording: $e');
    }
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
    _recordingTimer?.cancel();
    _recordingTimer = null;

    if (_currentRecordingPath != null) {
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    _currentRecordingPath = null;
    _recordingState = RecordingState.idle;
    _recordingDuration = Duration.zero;
    notifyListeners();
  }

  Future<void> saveRecordingWithName(String name) async {
    if (_currentRecordingPath == null || _savedRecordings.length >= 3) return;

    final recording = SavedRecording(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      filePath: _currentRecordingPath!,
      durationSeconds: _recordingDuration.inSeconds.clamp(
        1,
        maxRecordingSeconds,
      ),
    );

    _savedRecordings.add(recording);
    _selectedRecordingIndex = _savedRecordings.length - 1;
    _recordingState = RecordingState.idle;
    _currentRecordingPath = null;
    _recordingDuration = Duration.zero;

    await _saveSavedRecordings();
    notifyListeners();
  }

  // ==================== Saved Recordings Management ====================

  void selectRecording(int index) {
    if (index >= 0 && index < _savedRecordings.length) {
      _selectedRecordingIndex = index;
      notifyListeners();
    }
  }

  Future<void> previewRecording(int index) async {
    if (index < 0 || index >= _savedRecordings.length) return;

    try {
      if (_previewingRecordingIndex == index) {
        await _previewPlayer.stop();
        _previewingRecordingIndex = null;
        notifyListeners();
        return;
      }

      await _previewPlayer.stop();
      await _previewPlayer.setFilePath(_savedRecordings[index].filePath);
      _previewPlayer.play();
      _previewingRecordingIndex = index;
      notifyListeners();
    } catch (e) {
      debugPrint('Error previewing recording: $e');
    }
  }

  Future<void> deleteRecording(int index) async {
    if (index < 0 || index >= _savedRecordings.length) return;

    // Delete file
    final file = File(_savedRecordings[index].filePath);
    if (await file.exists()) {
      await file.delete();
    }

    _savedRecordings.removeAt(index);

    // Adjust selected index
    if (_selectedRecordingIndex == index) {
      _selectedRecordingIndex = _savedRecordings.isNotEmpty ? 0 : null;
    } else if (_selectedRecordingIndex != null &&
        _selectedRecordingIndex! > index) {
      _selectedRecordingIndex = _selectedRecordingIndex! - 1;
    }

    await _saveSavedRecordings();
    notifyListeners();
  }

  /// Preview a background sound
  String? _previewingSoundId;
  bool get isPreviewPlaying => _previewingSoundId != null;

  Future<void> previewBackgroundSound(BackgroundSound sound) async {
    try {
      if (_previewingSoundId == sound.id) {
        await _previewPlayer.stop();
        _previewingSoundId = null;
        notifyListeners();
        return;
      }

      await _previewPlayer.stop();
      await _previewPlayer.setAsset(sound.assetPath);
      await _previewPlayer.setVolume(0.7);
      _previewPlayer.play();
      _previewingSoundId = sound.id;
      notifyListeners();

      // Auto-stop after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (_previewingSoundId == sound.id) {
          _previewPlayer.stop();
          _previewingSoundId = null;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Error previewing background: $e');
    }
  }

  // ==================== Playback ====================

  void setBackground(BackgroundSound? background) {
    _selectedBackground = background;

    // If playing, switch background music with fade
    if (_playbackState == PlaybackState.playing && background != null) {
      _switchBackgroundMusic(background);
    }

    notifyListeners();
  }

  Future<void> _switchBackgroundMusic(BackgroundSound newBackground) async {
    // Fade out current
    for (int i = 10; i >= 0; i--) {
      _backgroundPlayer.setVolume(_backgroundVolume * (i / 10));
      await Future.delayed(const Duration(milliseconds: 50));
    }

    await _backgroundPlayer.stop();
    await _backgroundPlayer.setAsset(newBackground.assetPath);
    await _backgroundPlayer.setLoopMode(LoopMode.all);
    _backgroundPlayer.play();

    // Fade in
    for (int i = 0; i <= 10; i++) {
      _backgroundPlayer.setVolume(_backgroundVolume * (i / 10));
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void setVoiceVolume(double volume) {
    _voiceVolume = volume.clamp(0.0, 1.0);
    _voicePlayer.setVolume(_voiceVolume);
    notifyListeners();
  }

  void setBackgroundVolume(double volume) {
    _backgroundVolume = volume.clamp(0.0, 1.0);
    _backgroundPlayer.setVolume(_backgroundVolume);
    notifyListeners();
  }

  Future<void> startPlayback({int durationMinutes = 30}) async {
    if (_selectedRecordingIndex == null || _savedRecordings.isEmpty) return;

    final recording = _savedRecordings[_selectedRecordingIndex!];

    try {
      // Stop preview
      await _previewPlayer.stop();
      _previewingRecordingIndex = null;

      // Set up voice player
      await _voicePlayer.setFilePath(recording.filePath);
      await _voicePlayer.setLoopMode(LoopMode.off); // Manual loop with pause
      await _voicePlayer.setVolume(_voiceVolume);

      // Set up background player
      if (_selectedBackground != null) {
        await _backgroundPlayer.setAsset(_selectedBackground!.assetPath);
        await _backgroundPlayer.setLoopMode(LoopMode.all);
        await _backgroundPlayer.setVolume(_backgroundVolume);
      }

      // Set timer
      _totalDuration = Duration(minutes: durationMinutes);
      _remainingDuration = _totalDuration;

      // Start playback
      _voicePlayer.play();
      if (_selectedBackground != null) {
        _backgroundPlayer.play();
      }

      _playbackState = PlaybackState.playing;

      // Countdown timer
      _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingDuration.inSeconds > 0) {
          _remainingDuration -= const Duration(seconds: 1);
          notifyListeners();
        } else {
          _onSessionComplete();
        }
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error starting playback: $e');
    }
  }

  void pausePlayback() {
    _voicePlayer.pause();
    _backgroundPlayer.pause();
    _playbackTimer?.cancel();
    _playbackState = PlaybackState.paused;
    notifyListeners();
  }

  void resumePlayback() {
    _voicePlayer.play();
    if (_selectedBackground != null) {
      _backgroundPlayer.play();
    }

    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingDuration.inSeconds > 0) {
        _remainingDuration -= const Duration(seconds: 1);
        notifyListeners();
      } else {
        _onSessionComplete();
      }
    });

    _playbackState = PlaybackState.playing;
    notifyListeners();
  }

  Future<void> stopPlayback() async {
    _playbackTimer?.cancel();
    _playbackTimer = null;

    await _voicePlayer.stop();
    await _backgroundPlayer.stop();

    _playbackState = PlaybackState.idle;
    _remainingDuration = _totalDuration;
    notifyListeners();
  }

  Future<void> _onSessionComplete() async {
    _playbackTimer?.cancel();
    _playbackTimer = null;

    // Fade out
    for (int i = 10; i >= 0; i--) {
      _voicePlayer.setVolume(_voiceVolume * (i / 10));
      _backgroundPlayer.setVolume(_backgroundVolume * (i / 10));
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await _voicePlayer.stop();
    await _backgroundPlayer.stop();

    // Restore volumes
    _voicePlayer.setVolume(_voiceVolume);
    _backgroundPlayer.setVolume(_backgroundVolume);

    // Log session
    final log = SessionLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      completedAt: DateTime.now(),
      durationMinutes: _totalDuration.inMinutes,
      recordingName: _selectedRecordingIndex != null
          ? _savedRecordings[_selectedRecordingIndex!].name
          : null,
    );
    _sessionHistory.insert(0, log);
    await _saveSessionHistory();

    _playbackState = PlaybackState.idle;
    notifyListeners();
  }

  // ==================== Persistence ====================

  Future<void> _loadSavedRecordings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('affirmation_recordings');
      if (json != null) {
        final list = jsonDecode(json) as List;
        _savedRecordings = list
            .map((e) => SavedRecording.fromJson(e as Map<String, dynamic>))
            .toList();

        // Auto-select first if available
        if (_savedRecordings.isNotEmpty) {
          _selectedRecordingIndex = 0;
        }
      }
    } catch (e) {
      debugPrint('Error loading recordings: $e');
    }
  }

  Future<void> _saveSavedRecordings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_savedRecordings.map((e) => e.toJson()).toList());
      await prefs.setString('affirmation_recordings', json);
    } catch (e) {
      debugPrint('Error saving recordings: $e');
    }
  }

  Future<void> _loadSessionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('affirmation_session_history');
      if (json != null) {
        final list = jsonDecode(json) as List;
        _sessionHistory = list
            .map((e) => SessionLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading session history: $e');
    }
  }

  Future<void> _saveSessionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep only last 20 sessions
      final toSave = _sessionHistory.take(20).toList();
      final json = jsonEncode(toSave.map((e) => e.toJson()).toList());
      await prefs.setString('affirmation_session_history', json);
    } catch (e) {
      debugPrint('Error saving session history: $e');
    }
  }

  // ==================== Reset ====================

  void resetFlow() {
    _currentStep = 0;
    _playbackState = PlaybackState.idle;
    _remainingDuration = _totalDuration;
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    _recorder.dispose();
    _voicePlayer.dispose();
    _backgroundPlayer.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }
}
