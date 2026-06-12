import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/core/reminders/data/reminder_preferences_repository.dart';
import 'package:me_hub/core/reminders/domain/reminder_feature.dart';
import 'package:me_hub/core/reminders/domain/reminder_preferences.dart';
import 'package:me_hub/core/reminders/domain/reminder_request.dart';
import 'package:me_hub/core/reminders/presentation/reminder_settings_provider.dart';
import 'package:me_hub/core/reminders/services/reminder_coordinator.dart';
import 'package:me_hub/core/reminders/services/reminder_id_registry.dart';
import 'package:me_hub/core/reminders/services/reminder_notification_gateway.dart';
import 'package:me_hub/features/routines/domain/entities/routine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('denied permission never creates an active schedule', () async {
    final fixture = await _createFixture(
      permission: NotificationPermissionState.denied,
      preferences: ReminderPreferences.defaults(
        masterEnabled: true,
      ).setFeatureEnabled(ReminderFeature.mood, true),
    );

    await fixture.coordinator.reconcileDailyFeature(
      feature: ReminderFeature.mood,
      completedToday: false,
      actionable: true,
      title: 'Mood',
      body: 'Check in',
      payload: 'kora://mood',
      now: DateTime(2026, 6, 8, 9),
    );

    expect(fixture.gateway.scheduled, isEmpty);
  });

  test('denied permission preserves the desired feature toggle', () async {
    final fixture = await _createFixture(
      permission: NotificationPermissionState.denied,
      preferences: ReminderPreferences.defaults(),
    );
    final provider = ReminderSettingsProvider(fixture.coordinator);

    final allowed = await provider.setFeatureEnabled(
      ReminderFeature.mood,
      true,
    );

    expect(allowed, isFalse);
    expect(provider.preferences.masterEnabled, isTrue);
    expect(provider.preferences.isEnabled(ReminderFeature.mood), isTrue);
    expect(fixture.gateway.scheduled, isEmpty);
  });

  test('disabling one feature leaves another namespace scheduled', () async {
    final fixture = await _createFixture(
      preferences: ReminderPreferences.defaults(masterEnabled: true)
          .setFeatureEnabled(ReminderFeature.mood, true)
          .setFeatureEnabled(ReminderFeature.water, true),
    );

    await fixture.coordinator.reconcileDailyFeature(
      feature: ReminderFeature.mood,
      completedToday: false,
      actionable: true,
      title: 'Mood',
      body: 'Check in',
      payload: 'kora://mood',
      now: DateTime(2026, 6, 8, 9),
    );
    await fixture.coordinator.reconcileWater(
      goalReached: false,
      now: DateTime(2026, 6, 8, 7),
    );
    final waterIds = fixture.gateway.scheduled.entries
        .where((entry) => entry.value.namespace == 'feature:water')
        .map((entry) => entry.key)
        .toSet();

    await fixture.coordinator.setFeatureEnabled(ReminderFeature.mood, false);

    expect(waterIds, isNotEmpty);
    expect(fixture.gateway.scheduled.keys, containsAll(waterIds));
    expect(
      fixture.gateway.scheduled.values.where(
        (request) => request.namespace == 'feature:mood',
      ),
      isEmpty,
    );
  });

  test(
    'master off cancels owned schedules and master on restores them',
    () async {
      final fixture = await _createFixture(
        preferences: ReminderPreferences.defaults(
          masterEnabled: true,
        ).setFeatureEnabled(ReminderFeature.mood, true),
      );
      await fixture.coordinator.reconcileDailyFeature(
        feature: ReminderFeature.mood,
        completedToday: false,
        actionable: true,
        title: 'Mood',
        body: 'Check in',
        payload: 'kora://mood',
        now: DateTime(2026, 6, 8, 9),
      );
      expect(fixture.gateway.scheduled, hasLength(1));

      await fixture.coordinator.setMasterEnabled(false);
      expect(fixture.gateway.scheduled, isEmpty);

      await fixture.coordinator.setMasterEnabled(true);
      expect(fixture.gateway.scheduled, hasLength(1));
    },
  );

  test('routine lead time is reflected in the scheduled request', () async {
    final fixture = await _createFixture(
      preferences: ReminderPreferences.defaults(masterEnabled: true),
    );
    final routine = Routine(
      id: 'morning',
      name: 'Morning routine',
      items: const [],
      timeHour: 10,
      timeMinute: 0,
      selectedDays: const [0],
      reminderEnabled: true,
      reminderMinutesBefore: 15,
    );

    await fixture.coordinator.reconcileRoutine(
      routine,
      now: DateTime(2026, 6, 8, 9),
    );

    final request = fixture.gateway.scheduled.values.single;
    expect(request.scheduledAt, DateTime(2026, 6, 8, 9, 45));
    expect(request.payload, 'kora://routine/morning');

    await fixture.coordinator.removeRoutine(routine.id);
    expect(fixture.gateway.scheduled, isEmpty);
  });
}

Future<_Fixture> _createFixture({
  NotificationPermissionState permission = NotificationPermissionState.granted,
  required ReminderPreferences preferences,
}) async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final repository = ReminderPreferencesRepository(sharedPreferences);
  await repository.save(preferences);
  final gateway = _FakeNotificationGateway(permission);
  final coordinator = ReminderCoordinator(
    notifications: gateway,
    preferencesRepository: repository,
    idRegistry: ReminderIdRegistry(sharedPreferences),
  );
  await coordinator.initialize(hasLegacyReminders: false);
  return _Fixture(coordinator, gateway);
}

class _Fixture {
  final ReminderCoordinator coordinator;
  final _FakeNotificationGateway gateway;

  const _Fixture(this.coordinator, this.gateway);
}

class _FakeNotificationGateway implements ReminderNotificationGateway {
  NotificationPermissionState permission;
  final Map<int, ReminderRequest> scheduled = {};
  bool openedSettings = false;
  int cancelAllCalls = 0;

  _FakeNotificationGateway(this.permission);

  @override
  Future<void> cancelAllNotifications() async {
    cancelAllCalls++;
    scheduled.clear();
  }

  @override
  Future<void> cancelNotification(int id) async {
    scheduled.remove(id);
  }

  @override
  Future<NotificationPermissionState> getPermissionState() async => permission;

  @override
  Future<void> openNotificationSettings() async {
    openedSettings = true;
  }

  @override
  Future<NotificationPermissionState> requestPermission() async => permission;

  @override
  Future<void> scheduleReminder(int id, ReminderRequest request) async {
    scheduled[id] = request;
  }
}
