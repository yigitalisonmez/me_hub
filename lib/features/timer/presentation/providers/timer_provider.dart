import 'dart:async';
import 'package:flutter/foundation.dart';

enum TimerMode { pomodoro, countdown, stopwatch }

enum TimerState { idle, running, paused }

class TimerProvider extends ChangeNotifier {
  TimerMode _mode = TimerMode.pomodoro;
  TimerState _state = TimerState.idle;

  // Pomodoro settings
  int _workDuration = 25 * 60; // 25 minutes in seconds
  int _breakDuration = 5 * 60; // 5 minutes
  int _currentSession = 1;
  int _totalSessions = 4;
  bool _isBreaktime = false;

  // Timer state
  int _remainingSeconds = 25 * 60;
  int _totalSeconds = 25 * 60;
  int _elapsedSeconds = 0; // For stopwatch

  Timer? _timer;

  // Getters
  TimerMode get mode => _mode;
  TimerState get state => _state;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  int get elapsedSeconds => _elapsedSeconds;
  int get currentSession => _currentSession;
  int get totalSessions => _totalSessions;
  bool get isBreaktime => _isBreaktime;
  int get workDuration => _workDuration;
  int get breakDuration => _breakDuration;

  double get progress {
    if (_mode == TimerMode.stopwatch) {
      return 0; // Stopwatch doesn't have progress
    }
    if (_totalSeconds == 0) return 0;
    return 1 - (_remainingSeconds / _totalSeconds);
  }

  String get formattedTime {
    final seconds = _mode == TimerMode.stopwatch
        ? _elapsedSeconds
        : _remainingSeconds;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String get statusText {
    if (_mode == TimerMode.pomodoro) {
      return _isBreaktime ? 'Break Time' : 'Focus Time';
    } else if (_mode == TimerMode.countdown) {
      return 'Countdown';
    } else {
      return 'Stopwatch';
    }
  }

  // Mode switching
  void setMode(TimerMode newMode) {
    if (_state != TimerState.idle) {
      reset();
    }
    _mode = newMode;
    _resetToDefaults();
    notifyListeners();
  }

  void _resetToDefaults() {
    switch (_mode) {
      case TimerMode.pomodoro:
        _remainingSeconds = _workDuration;
        _totalSeconds = _workDuration;
        _isBreaktime = false;
        break;
      case TimerMode.countdown:
        _remainingSeconds = 10 * 60; // Default 10 minutes
        _totalSeconds = 10 * 60;
        break;
      case TimerMode.stopwatch:
        _elapsedSeconds = 0;
        break;
    }
  }

  // Set countdown duration
  void setCountdownDuration(int minutes) {
    if (_mode != TimerMode.countdown) return;
    _remainingSeconds = minutes * 60;
    _totalSeconds = minutes * 60;
    notifyListeners();
  }

  // Timer controls
  void start() {
    if (_state == TimerState.running) return;

    _state = TimerState.running;
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    notifyListeners();
  }

  void pause() {
    if (_state != TimerState.running) return;

    _state = TimerState.paused;
    _timer?.cancel();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _state = TimerState.idle;
    _resetToDefaults();
    if (_mode == TimerMode.pomodoro) {
      _currentSession = 1;
      _isBreaktime = false;
    }
    notifyListeners();
  }

  void _onTick(Timer timer) {
    if (_mode == TimerMode.stopwatch) {
      _elapsedSeconds++;
      notifyListeners();
      return;
    }

    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
    } else {
      _onTimerComplete();
    }
  }

  void _onTimerComplete() {
    _timer?.cancel();

    if (_mode == TimerMode.pomodoro) {
      if (_isBreaktime) {
        // Break finished, start next work session
        _isBreaktime = false;
        if (_currentSession < _totalSessions) {
          _currentSession++;
        } else {
          _currentSession = 1; // Reset to first session
        }
        _remainingSeconds = _workDuration;
        _totalSeconds = _workDuration;
      } else {
        // Work finished, start break
        _isBreaktime = true;
        _remainingSeconds = _breakDuration;
        _totalSeconds = _breakDuration;
      }
      _state = TimerState.idle;
    } else {
      // Countdown finished
      _state = TimerState.idle;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
