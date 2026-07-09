import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/core/services/timer_notification_gateway.dart';
import 'package:me_hub/features/timer/presentation/providers/timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimerProvider', () {
    test('uses wall clock time and schedules countdown completion', () async {
      final clock = _MutableClock(DateTime(2026, 6, 12, 10));
      final notifications = _FakeTimerNotificationGateway();
      final provider = TimerProvider(
        notifications: notifications,
        now: clock.call,
        observeLifecycle: false,
      );

      provider.setMode(TimerMode.countdown);
      provider.setCountdownDuration(1);
      provider.start();
      await _flushAsyncWork();

      expect(provider.state, TimerState.running);
      expect(notifications.scheduled, hasLength(1));
      expect(
        notifications.scheduled.single.scheduledAt,
        DateTime(2026, 6, 12, 10, 1),
      );

      clock.advance(const Duration(seconds: 37));
      provider.syncWithClock();

      expect(provider.remainingSeconds, 23);
      provider.dispose();
    });

    test('completes countdown after time elapsed while app was away', () async {
      final clock = _MutableClock(DateTime(2026, 6, 12, 10));
      final notifications = _FakeTimerNotificationGateway();
      final provider = TimerProvider(
        notifications: notifications,
        now: clock.call,
        observeLifecycle: false,
      );

      provider.setMode(TimerMode.countdown);
      provider.setCountdownDuration(1);
      provider.start();
      await _flushAsyncWork();
      notifications.clear();

      clock.advance(const Duration(seconds: 61));
      provider.syncWithClock();

      expect(provider.state, TimerState.idle);
      expect(provider.remainingSeconds, 0);
      expect(notifications.cancelCount, 0);
      provider.dispose();
    });

    test('pause freezes elapsed time and cancels completion alert', () async {
      final clock = _MutableClock(DateTime(2026, 6, 12, 10));
      final notifications = _FakeTimerNotificationGateway();
      final provider = TimerProvider(
        notifications: notifications,
        now: clock.call,
        observeLifecycle: false,
      );

      provider.setMode(TimerMode.countdown);
      provider.setCountdownDuration(1);
      provider.start();
      await _flushAsyncWork();
      notifications.clear();

      clock.advance(const Duration(seconds: 15));
      provider.pause();
      await _flushAsyncWork();
      expect(provider.remainingSeconds, 45);
      expect(notifications.cancelCount, 1);

      clock.advance(const Duration(minutes: 2));
      provider.syncWithClock();
      expect(provider.remainingSeconds, 45);
      provider.dispose();
    });

    test('stopwatch catches up from its start timestamp', () {
      final clock = _MutableClock(DateTime(2026, 6, 12, 10));
      final provider = TimerProvider(now: clock.call, observeLifecycle: false);

      provider.setMode(TimerMode.stopwatch);
      provider.start();
      clock.advance(const Duration(minutes: 2, seconds: 7));
      provider.syncWithClock();

      expect(provider.elapsedSeconds, 127);
      expect(provider.formattedTime, '02:07');
      provider.dispose();
    });

    test('pomodoro completion advances to the break phase', () {
      final clock = _MutableClock(DateTime(2026, 6, 12, 10));
      final provider = TimerProvider(now: clock.call, observeLifecycle: false);

      provider.start();
      clock.advance(const Duration(minutes: 25, seconds: 1));
      provider.syncWithClock();

      expect(provider.state, TimerState.idle);
      expect(provider.isBreaktime, isTrue);
      expect(provider.remainingSeconds, 5 * 60);
      provider.dispose();
    });

    test('restores a running countdown from persisted target time', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final clock = _MutableClock(DateTime(2026, 6, 12, 10));
      final firstProvider = TimerProvider(
        preferences: preferences,
        now: clock.call,
        observeLifecycle: false,
      );

      firstProvider.setMode(TimerMode.countdown);
      firstProvider.setCountdownDuration(1);
      firstProvider.start();
      await _flushAsyncWork();
      firstProvider.dispose();

      clock.advance(const Duration(seconds: 30));
      final restoredProvider = TimerProvider(
        preferences: preferences,
        now: clock.call,
        observeLifecycle: false,
      );

      expect(restoredProvider.mode, TimerMode.countdown);
      expect(restoredProvider.state, TimerState.running);
      expect(restoredProvider.remainingSeconds, 30);
      restoredProvider.dispose();
    });
  });
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _MutableClock {
  _MutableClock(this.value);

  DateTime value;

  DateTime call() => value;

  void advance(Duration duration) {
    value = value.add(duration);
  }
}

class _ScheduledTimerNotification {
  const _ScheduledTimerNotification({
    required this.scheduledAt,
    required this.title,
    required this.body,
  });

  final DateTime scheduledAt;
  final String title;
  final String body;
}

class _FakeTimerNotificationGateway implements TimerNotificationGateway {
  final List<_ScheduledTimerNotification> scheduled = [];
  int cancelCount = 0;

  @override
  Future<void> cancelTimerCompletion() async {
    cancelCount++;
  }

  @override
  Future<void> scheduleTimerCompletion({
    required DateTime scheduledAt,
    required String title,
    required String body,
  }) async {
    scheduled.add(
      _ScheduledTimerNotification(
        scheduledAt: scheduledAt,
        title: title,
        body: body,
      ),
    );
  }

  void clear() {
    scheduled.clear();
    cancelCount = 0;
  }
}
