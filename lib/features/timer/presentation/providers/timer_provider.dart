import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/timer_notification_gateway.dart';

enum TimerMode { pomodoro, countdown, stopwatch }

enum TimerState { idle, running, paused }

class TimerProvider extends ChangeNotifier with WidgetsBindingObserver {
  TimerProvider({
    TimerNotificationGateway? notifications,
    SharedPreferences? preferences,
    DateTime Function()? now,
    bool observeLifecycle = true,
  }) : _notifications = notifications,
       _preferences = preferences,
       _now = now ?? DateTime.now,
       _observesLifecycle = observeLifecycle {
    _restoreState();
    if (_observesLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
    if (_state == TimerState.running) {
      syncWithClock();
      if (_state == TimerState.running) {
        _startTicker();
        if (_mode != TimerMode.stopwatch && _targetAt != null) {
          _queueCompletionNotification(_targetAt!);
        }
      }
    }
  }

  static const _workDuration = 25 * 60;
  static const _breakDuration = 5 * 60;
  static const _totalSessions = 4;
  static const _preferencesPrefix = 'focus_timer.';

  final TimerNotificationGateway? _notifications;
  final SharedPreferences? _preferences;
  final DateTime Function() _now;
  final bool _observesLifecycle;

  TimerMode _mode = TimerMode.pomodoro;
  TimerState _state = TimerState.idle;
  int _currentSession = 1;
  bool _isBreaktime = false;
  int _remainingSeconds = _workDuration;
  int _totalSeconds = _workDuration;
  int _elapsedSeconds = 0;

  Timer? _ticker;
  DateTime? _targetAt;
  DateTime? _stopwatchStartedAt;
  int _elapsedAtStart = 0;
  Future<void> _notificationOperations = Future<void>.value();

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
    if (_mode == TimerMode.stopwatch || _totalSeconds == 0) return 0;
    return 1 - (_remainingSeconds / _totalSeconds);
  }

  String get formattedTime {
    final seconds = _mode == TimerMode.stopwatch
        ? _elapsedSeconds
        : _remainingSeconds;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  String get statusText {
    return switch (_mode) {
      TimerMode.pomodoro => _isBreaktime ? 'Break Time' : 'Focus Time',
      TimerMode.countdown => 'Countdown',
      TimerMode.stopwatch => 'Stopwatch',
    };
  }

  void setMode(TimerMode newMode) {
    if (_mode == newMode) return;
    _stopRunningTimer(cancelNotification: true);
    _mode = newMode;
    _state = TimerState.idle;
    _resetToDefaults();
    _persistState();
    notifyListeners();
  }

  void setCountdownDuration(int minutes) {
    if (_mode != TimerMode.countdown || _state == TimerState.running) return;
    final duration = math.max(1, minutes) * 60;
    _remainingSeconds = duration;
    _totalSeconds = duration;
    _state = TimerState.idle;
    _persistState();
    notifyListeners();
  }

  void start() {
    if (_state == TimerState.running) return;
    if (_mode != TimerMode.stopwatch && _remainingSeconds <= 0) {
      _resetToDefaults();
    }

    final now = _now();
    _state = TimerState.running;
    if (_mode == TimerMode.stopwatch) {
      _elapsedAtStart = _elapsedSeconds;
      _stopwatchStartedAt = now;
    } else {
      _targetAt = now.add(Duration(seconds: _remainingSeconds));
      _queueCompletionNotification(_targetAt!);
    }

    _startTicker();
    _persistState();
    notifyListeners();
  }

  void pause() {
    if (_state != TimerState.running) return;
    syncWithClock();
    if (_state != TimerState.running) return;

    _state = TimerState.paused;
    _ticker?.cancel();
    _ticker = null;
    _targetAt = null;
    _stopwatchStartedAt = null;
    _elapsedAtStart = _elapsedSeconds;
    _queueNotificationCancellation();
    _persistState();
    notifyListeners();
  }

  void reset() {
    _stopRunningTimer(cancelNotification: true);
    _state = TimerState.idle;
    _currentSession = 1;
    _isBreaktime = false;
    _resetToDefaults();
    _persistState();
    notifyListeners();
  }

  void skip() {
    if (_mode != TimerMode.pomodoro) {
      reset();
      return;
    }

    _stopRunningTimer(cancelNotification: true);
    _advancePomodoroPhase();
    _state = TimerState.idle;
    _persistState();
    notifyListeners();
  }

  void syncWithClock() {
    if (_state != TimerState.running) return;

    if (_mode == TimerMode.stopwatch) {
      final startedAt = _stopwatchStartedAt;
      if (startedAt == null) return;
      final elapsed = math.max(0, _now().difference(startedAt).inSeconds);
      final nextElapsed = _elapsedAtStart + elapsed;
      if (nextElapsed != _elapsedSeconds) {
        _elapsedSeconds = nextElapsed;
        notifyListeners();
      }
      return;
    }

    final targetAt = _targetAt;
    if (targetAt == null) return;
    final milliseconds = targetAt.difference(_now()).inMilliseconds;
    final nextRemaining = milliseconds <= 0
        ? 0
        : (milliseconds / Duration.millisecondsPerSecond).ceil();

    if (nextRemaining <= 0) {
      _remainingSeconds = 0;
      _completeCurrentInterval();
      return;
    }

    if (nextRemaining != _remainingSeconds) {
      _remainingSeconds = nextRemaining;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncWithClock();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _persistState();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => syncWithClock(),
    );
  }

  void _completeCurrentInterval() {
    _ticker?.cancel();
    _ticker = null;
    _targetAt = null;
    _stopwatchStartedAt = null;
    unawaited(HapticFeedback.heavyImpact());

    if (_mode == TimerMode.pomodoro) {
      _advancePomodoroPhase();
    }
    _state = TimerState.idle;
    _persistState();
    notifyListeners();
  }

  void _advancePomodoroPhase() {
    if (_isBreaktime) {
      _isBreaktime = false;
      _currentSession = _currentSession < _totalSessions
          ? _currentSession + 1
          : 1;
      _remainingSeconds = _workDuration;
      _totalSeconds = _workDuration;
    } else {
      _isBreaktime = true;
      _remainingSeconds = _breakDuration;
      _totalSeconds = _breakDuration;
    }
  }

  void _stopRunningTimer({required bool cancelNotification}) {
    _ticker?.cancel();
    _ticker = null;
    _targetAt = null;
    _stopwatchStartedAt = null;
    _elapsedAtStart = _elapsedSeconds;
    if (cancelNotification) {
      _queueNotificationCancellation();
    }
  }

  void _resetToDefaults() {
    switch (_mode) {
      case TimerMode.pomodoro:
        _remainingSeconds = _workDuration;
        _totalSeconds = _workDuration;
        _elapsedSeconds = 0;
        _isBreaktime = false;
      case TimerMode.countdown:
        _remainingSeconds = 10 * 60;
        _totalSeconds = 10 * 60;
        _elapsedSeconds = 0;
      case TimerMode.stopwatch:
        _remainingSeconds = 0;
        _totalSeconds = 0;
        _elapsedSeconds = 0;
    }
  }

  void _queueCompletionNotification(DateTime scheduledAt) {
    final notifications = _notifications;
    if (notifications == null) return;

    final (title, body) = switch (_mode) {
      TimerMode.pomodoro when _isBreaktime => (
        'Break complete',
        'Ready for the next focus round?',
      ),
      TimerMode.pomodoro => (
        'Focus session complete',
        'Nice work. It is time for a short break.',
      ),
      TimerMode.countdown => ('Timer complete', 'Your countdown has finished.'),
      TimerMode.stopwatch => ('', ''),
    };

    _notificationOperations = _notificationOperations
        .then(
          (_) => notifications.scheduleTimerCompletion(
            scheduledAt: scheduledAt,
            title: title,
            body: body,
          ),
        )
        .catchError(_logNotificationError);
  }

  void _queueNotificationCancellation() {
    final notifications = _notifications;
    if (notifications == null) return;
    _notificationOperations = _notificationOperations
        .then((_) => notifications.cancelTimerCompletion())
        .catchError(_logNotificationError);
  }

  void _logNotificationError(Object error, StackTrace stackTrace) {
    debugPrint('Timer notification operation failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  void _restoreState() {
    final preferences = _preferences;
    if (preferences == null) return;

    _mode = _enumValue(
      TimerMode.values,
      preferences.getString('${_preferencesPrefix}mode'),
      TimerMode.pomodoro,
    );
    _state = _enumValue(
      TimerState.values,
      preferences.getString('${_preferencesPrefix}state'),
      TimerState.idle,
    );
    _remainingSeconds =
        preferences.getInt('${_preferencesPrefix}remainingSeconds') ??
        _workDuration;
    _totalSeconds =
        preferences.getInt('${_preferencesPrefix}totalSeconds') ??
        _workDuration;
    _elapsedSeconds =
        preferences.getInt('${_preferencesPrefix}elapsedSeconds') ?? 0;
    _elapsedAtStart =
        preferences.getInt('${_preferencesPrefix}elapsedAtStart') ??
        _elapsedSeconds;
    _currentSession =
        preferences.getInt('${_preferencesPrefix}currentSession') ?? 1;
    _isBreaktime =
        preferences.getBool('${_preferencesPrefix}isBreaktime') ?? false;

    final targetMilliseconds = preferences.getInt(
      '${_preferencesPrefix}targetAt',
    );
    final stopwatchMilliseconds = preferences.getInt(
      '${_preferencesPrefix}stopwatchStartedAt',
    );
    if (targetMilliseconds != null && targetMilliseconds > 0) {
      _targetAt = DateTime.fromMillisecondsSinceEpoch(targetMilliseconds);
    }
    if (stopwatchMilliseconds != null && stopwatchMilliseconds > 0) {
      _stopwatchStartedAt = DateTime.fromMillisecondsSinceEpoch(
        stopwatchMilliseconds,
      );
    }

    if (_state == TimerState.running) {
      final hasClock = _mode == TimerMode.stopwatch
          ? _stopwatchStartedAt != null
          : _targetAt != null;
      if (!hasClock) _state = TimerState.paused;
    }
  }

  void _persistState() {
    final preferences = _preferences;
    if (preferences == null) return;

    unawaited(
      Future.wait([
        preferences.setString('${_preferencesPrefix}mode', _mode.name),
        preferences.setString('${_preferencesPrefix}state', _state.name),
        preferences.setInt(
          '${_preferencesPrefix}remainingSeconds',
          _remainingSeconds,
        ),
        preferences.setInt('${_preferencesPrefix}totalSeconds', _totalSeconds),
        preferences.setInt(
          '${_preferencesPrefix}elapsedSeconds',
          _elapsedSeconds,
        ),
        preferences.setInt(
          '${_preferencesPrefix}elapsedAtStart',
          _elapsedAtStart,
        ),
        preferences.setInt(
          '${_preferencesPrefix}currentSession',
          _currentSession,
        ),
        preferences.setBool('${_preferencesPrefix}isBreaktime', _isBreaktime),
        preferences.setInt(
          '${_preferencesPrefix}targetAt',
          _targetAt?.millisecondsSinceEpoch ?? 0,
        ),
        preferences.setInt(
          '${_preferencesPrefix}stopwatchStartedAt',
          _stopwatchStartedAt?.millisecondsSinceEpoch ?? 0,
        ),
      ]),
    );
  }

  T _enumValue<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (_observesLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }
}
