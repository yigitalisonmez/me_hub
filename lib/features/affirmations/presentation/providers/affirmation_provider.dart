import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../data/models/affirmation_session.dart';
import '../../data/models/background_sound.dart';
import '../../data/repositories/affirmation_repository.dart';

enum RecordingState { idle, recording, recorded }

enum PlaybackState { idle, playing, paused }

/// Provider for managing affirmation recording, playback, and session state
class AffirmationProvider extends ChangeNotifier {
  final AffirmationRepository _repository = AffirmationRepository();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _previewPlayer = AudioPlayer(); // For previews

  // Recording state
  RecordingState _recordingState = RecordingState.idle;
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  // Playback state
  PlaybackState _playbackState = PlaybackState.idle;
  BackgroundSound? _selectedBackground;

  // Timer state
  Duration _remainingDuration = const Duration(minutes: 30);
  Duration _totalDuration = const Duration(minutes: 30);
  Timer? _playbackTimer;
  bool _isLooping = false;

  // Volume controls
  double _voiceVolume = 1.0;
  double _backgroundVolume = 0.5;

  // Sessions
  List<AffirmationSession> _sessions = [];
  AffirmationSession? _currentSession;

  // Preview state
  bool _isPreviewPlaying = false;
  String? _previewingSoundId;

  // Getters
  RecordingState get recordingState => _recordingState;
  String? get currentRecordingPath => _currentRecordingPath;
  Duration get recordingDuration => _recordingDuration;

  PlaybackState get playbackState => _playbackState;
  BackgroundSound? get selectedBackground => _selectedBackground;
  List<BackgroundSound> get availableBackgrounds => BackgroundSound.presets;

  Duration get remainingDuration => _remainingDuration;
  Duration get totalDuration => _totalDuration;
  bool get isLooping => _isLooping;

  double get voiceVolume => _voiceVolume;
  double get backgroundVolume => _backgroundVolume;

  List<AffirmationSession> get sessions => _sessions;
  AffirmationSession? get currentSession => _currentSession;
  int get totalCompletedSessions => _repository.getTotalCompletedSessions();

  bool get isPreviewPlaying => _isPreviewPlaying;
  String? get previewingSoundId => _previewingSoundId;
  AudioPlayer get previewPlayer => _previewPlayer; // For StreamBuilder access

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

  /// Initialize the provider
  Future<void> init() async {
    await _repository.init();
    _sessions = _repository.getAllSessions();

    // Set default background
    if (BackgroundSound.presets.isNotEmpty) {
      _selectedBackground = BackgroundSound.presets.first;
    }

    // Listen to player states
    _voicePlayer.playerStateStream.listen(_onVoicePlayerStateChanged);
    _previewPlayer.playerStateStream.listen(_onPreviewPlayerStateChanged);

    notifyListeners();
  }

  void _onVoicePlayerStateChanged(PlayerState state) {
    // Handle player completion for looping
    if (state.processingState == ProcessingState.completed && _isLooping) {
      _voicePlayer.seek(Duration.zero);
      _voicePlayer.play();
    }
  }

  void _onPreviewPlayerStateChanged(PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      _isPreviewPlaying = false;
      _previewingSoundId = null;
      notifyListeners();
    }
  }

  // ==================== Recording ====================

  /// Check if microphone permission is granted
  Future<bool> hasRecordingPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording
  Future<void> startRecording() async {
    try {
      if (!await hasRecordingPermission()) {
        return;
      }

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

      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration += const Duration(seconds: 1);
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  /// Stop recording
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

  /// Cancel recording and delete file
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

  // ==================== Preview ====================

  /// Preview the recorded affirmation
  Future<void> playRecordingPreview() async {
    if (_currentRecordingPath == null) return;

    try {
      if (_isPreviewPlaying && _previewingSoundId == 'recording') {
        // Stop if already playing recording
        await stopPreview();
        return;
      }

      await stopPreview();
      await _previewPlayer.setFilePath(_currentRecordingPath!);
      await _previewPlayer.setVolume(1.0);
      _previewPlayer.play();
      _isPreviewPlaying = true;
      _previewingSoundId = 'recording';
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing recording preview: $e');
    }
  }

  /// Preview a background sound
  Future<void> previewBackgroundSound(BackgroundSound sound) async {
    try {
      if (_isPreviewPlaying && _previewingSoundId == sound.id) {
        // Stop if already playing this sound
        await stopPreview();
        return;
      }

      await stopPreview();
      await _previewPlayer.setAsset(sound.assetPath);
      await _previewPlayer.setVolume(0.7);
      _previewPlayer.play();
      _isPreviewPlaying = true;
      _previewingSoundId = sound.id;
      notifyListeners();

      // Auto-stop after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (_previewingSoundId == sound.id) {
          stopPreview();
        }
      });
    } catch (e) {
      debugPrint('Error previewing background: $e');
    }
  }

  /// Stop preview playback
  Future<void> stopPreview() async {
    await _previewPlayer.stop();
    _isPreviewPlaying = false;
    _previewingSoundId = null;
    notifyListeners();
  }

  // ==================== Playback ====================

  /// Set background sound
  void setBackground(BackgroundSound? background) {
    _selectedBackground = background;
    notifyListeners();
  }

  /// Set voice volume (0.0 - 1.0)
  void setVoiceVolume(double volume) {
    _voiceVolume = volume.clamp(0.0, 1.0);
    _voicePlayer.setVolume(_voiceVolume);
    notifyListeners();
  }

  /// Set background volume (0.0 - 1.0)
  void setBackgroundVolume(double volume) {
    _backgroundVolume = volume.clamp(0.0, 1.0);
    _backgroundPlayer.setVolume(_backgroundVolume);
    notifyListeners();
  }

  /// Start playback with loop
  Future<void> startPlayback({int durationMinutes = 30}) async {
    if (_currentRecordingPath == null) return;

    // Stop any preview first
    await stopPreview();

    try {
      // Set up voice player
      await _voicePlayer.setFilePath(_currentRecordingPath!);
      await _voicePlayer.setLoopMode(LoopMode.all);
      await _voicePlayer.setVolume(_voiceVolume);

      // Set up background player if selected
      if (_selectedBackground != null) {
        await _backgroundPlayer.setAsset(_selectedBackground!.assetPath);
        await _backgroundPlayer.setLoopMode(LoopMode.all);
        await _backgroundPlayer.setVolume(_backgroundVolume);
      }

      // Set timer
      _totalDuration = Duration(minutes: durationMinutes);
      _remainingDuration = _totalDuration;
      _isLooping = true;

      // Start playback
      _voicePlayer.play();
      if (_selectedBackground != null) {
        _backgroundPlayer.play();
      }

      _playbackState = PlaybackState.playing;

      // Start countdown timer
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

  /// Pause playback
  void pausePlayback() {
    _voicePlayer.pause();
    _backgroundPlayer.pause();
    _playbackTimer?.cancel();
    _playbackState = PlaybackState.paused;
    notifyListeners();
  }

  /// Resume playback
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

  /// Stop playback
  Future<void> stopPlayback() async {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _isLooping = false;

    await _voicePlayer.stop();
    await _backgroundPlayer.stop();

    _playbackState = PlaybackState.idle;
    _remainingDuration = _totalDuration;
    notifyListeners();
  }

  /// Fade out and complete session
  Future<void> _onSessionComplete() async {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _isLooping = false;

    // Fade out over 5 seconds
    const fadeSteps = 50;
    final voiceStep = _voiceVolume / fadeSteps;
    final bgStep = _backgroundVolume / fadeSteps;

    for (int i = 0; i < fadeSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      final newVoiceVol = (_voiceVolume - (voiceStep * (i + 1))).clamp(
        0.0,
        1.0,
      );
      final newBgVol = (_backgroundVolume - (bgStep * (i + 1))).clamp(0.0, 1.0);
      _voicePlayer.setVolume(newVoiceVol);
      _backgroundPlayer.setVolume(newBgVol);
    }

    await _voicePlayer.stop();
    await _backgroundPlayer.stop();

    // Restore volumes for next playback
    _voicePlayer.setVolume(_voiceVolume);
    _backgroundPlayer.setVolume(_backgroundVolume);

    // Increment completed sessions if we have a current session
    if (_currentSession != null) {
      await _repository.incrementCompletedSessions(_currentSession!.id);
      _sessions = _repository.getAllSessions();
    }

    _playbackState = PlaybackState.idle;
    notifyListeners();
  }

  // ==================== Sessions ====================

  /// Save current recording as a session
  Future<AffirmationSession?> saveSession(String name) async {
    if (_currentRecordingPath == null) return null;

    final session = AffirmationSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      recordingPath: _currentRecordingPath!,
      selectedBackgroundId: _selectedBackground?.id,
      backgroundVolume: _backgroundVolume,
      voiceVolume: _voiceVolume,
      createdAt: DateTime.now(),
    );

    await _repository.saveSession(session);
    _sessions = _repository.getAllSessions();
    _currentSession = session;
    notifyListeners();

    return session;
  }

  /// Load a saved session
  Future<void> loadSession(AffirmationSession session) async {
    _currentSession = session;
    _currentRecordingPath = session.recordingPath;
    _selectedBackground = session.selectedBackgroundId != null
        ? BackgroundSound.findById(session.selectedBackgroundId!)
        : null;
    _voiceVolume = session.voiceVolume;
    _backgroundVolume = session.backgroundVolume;
    _recordingState = RecordingState.recorded;
    notifyListeners();
  }

  /// Delete a session
  Future<void> deleteSession(String id) async {
    final session = _repository.getSession(id);
    if (session != null) {
      // Delete the recording file
      final file = File(session.recordingPath);
      if (await file.exists()) {
        await file.delete();
      }

      await _repository.deleteSession(id);
      _sessions = _repository.getAllSessions();

      if (_currentSession?.id == id) {
        _currentSession = null;
        _currentRecordingPath = null;
        _recordingState = RecordingState.idle;
      }

      notifyListeners();
    }
  }

  /// Clear current recording to start fresh
  void clearCurrentRecording() {
    _currentRecordingPath = null;
    _currentSession = null;
    _recordingState = RecordingState.idle;
    _recordingDuration = Duration.zero;
    stopPreview();
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
