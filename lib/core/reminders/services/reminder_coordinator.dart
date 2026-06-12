import '../data/reminder_preferences_repository.dart';
import '../domain/reminder_feature.dart';
import '../domain/reminder_preferences.dart';
import '../domain/reminder_request.dart';
import 'reminder_id_registry.dart';
import 'reminder_notification_gateway.dart';
import 'reminder_schedule_planner.dart';
import '../../../features/calendar/domain/entities/calendar_event.dart';
import '../../../features/routines/domain/entities/routine.dart';

class ReminderCoordinator {
  final ReminderNotificationGateway _notifications;
  final ReminderPreferencesRepository _preferencesRepository;
  final ReminderIdRegistry _idRegistry;
  final ReminderSchedulePlanner _planner;

  ReminderPreferences _preferences = ReminderPreferences.defaults();
  NotificationPermissionState _permissionState =
      NotificationPermissionState.unknown;
  final Map<
    ReminderFeature,
    ({
      bool completedToday,
      bool actionable,
      String title,
      String body,
      String payload,
    })
  >
  _dailyStates = {};
  bool _waterGoalReached = false;
  List<Routine> _routines = const [];
  List<CalendarEvent> _calendarEvents = const [];
  String? _weeklyInsight;
  String _weeklyInsightUserName = 'there';

  ReminderCoordinator({
    required ReminderNotificationGateway notifications,
    required ReminderPreferencesRepository preferencesRepository,
    required ReminderIdRegistry idRegistry,
    ReminderSchedulePlanner planner = const ReminderSchedulePlanner(),
  }) : _notifications = notifications,
       _preferencesRepository = preferencesRepository,
       _idRegistry = idRegistry,
       _planner = planner;

  ReminderPreferences get preferences => _preferences;
  NotificationPermissionState get permissionState => _permissionState;

  Future<bool> initialize({required bool hasLegacyReminders}) async {
    final result = await _preferencesRepository.load(
      hasLegacyReminders: hasLegacyReminders,
    );
    _preferences = result.preferences;
    _permissionState = await _notifications.getPermissionState();
    if (result.didMigrate) {
      await _notifications.cancelAllNotifications();
      await _idRegistry.clear();
    }
    return result.didMigrate;
  }

  Future<NotificationPermissionState> refreshPermissionState() async {
    return _permissionState = await _notifications.getPermissionState();
  }

  Future<NotificationPermissionState> requestPermission() async {
    return _permissionState = await _notifications.requestPermission();
  }

  Future<void> openSystemSettings() =>
      _notifications.openNotificationSettings();

  Future<void> setMasterEnabled(bool enabled) async {
    _preferences = _preferences.copyWith(masterEnabled: enabled);
    await _preferencesRepository.save(_preferences);
    if (!enabled) {
      await cancelAllOwned();
    } else {
      await reconcileAllCached();
    }
  }

  Future<void> setFeatureEnabled(ReminderFeature feature, bool enabled) async {
    _preferences = _preferences.setFeatureEnabled(feature, enabled);
    await _preferencesRepository.save(_preferences);
    if (!enabled) {
      await cancelNamespace(feature.namespace);
    } else {
      await _reconcileCachedFeature(feature);
    }
  }

  Future<void> setFeatureTime(
    ReminderFeature feature,
    ReminderTime time,
  ) async {
    _preferences = _preferences.setFeatureTime(feature, time);
    await _preferencesRepository.save(_preferences);
    await _reconcileCachedFeature(feature);
  }

  Future<void> setWaterSettings({
    required ReminderTime start,
    required ReminderTime end,
    required int intervalHours,
  }) async {
    _preferences = _preferences.copyWith(
      waterStart: start,
      waterEnd: end,
      waterIntervalHours: intervalHours,
    );
    await _preferencesRepository.save(_preferences);
    await reconcileWater(goalReached: _waterGoalReached);
  }

  Future<void> reconcileDailyFeature({
    required ReminderFeature feature,
    required bool completedToday,
    required bool actionable,
    required String title,
    required String body,
    required String payload,
    DateTime? now,
  }) async {
    _dailyStates[feature] = (
      completedToday: completedToday,
      actionable: actionable,
      title: title,
      body: body,
      payload: payload,
    );
    await _reconcile(
      feature.namespace,
      _planner.dailyFeature(
        feature: feature,
        preferences: _preferences,
        now: now ?? DateTime.now(),
        completedToday: completedToday,
        actionable: actionable,
        title: title,
        body: body,
        payload: payload,
      ),
    );
  }

  Future<void> reconcileWater({
    required bool goalReached,
    DateTime? now,
  }) async {
    _waterGoalReached = goalReached;
    await _reconcile(
      ReminderFeature.water.namespace,
      _planner.water(
        preferences: _preferences,
        now: now ?? DateTime.now(),
        goalReached: goalReached,
      ),
    );
  }

  Future<void> reconcileWeeklyInsight({
    required String? insight,
    required String userName,
    DateTime? now,
  }) async {
    _weeklyInsight = insight;
    _weeklyInsightUserName = userName;
    const feature = ReminderFeature.weeklyInsights;
    if (insight == null ||
        !_preferences.masterEnabled ||
        !_preferences.isEnabled(feature)) {
      await cancelNamespace(feature.namespace);
      return;
    }
    await _reconcile(feature.namespace, [
      _planner.weeklyInsight(
        preferences: _preferences,
        now: now ?? DateTime.now(),
        insight: insight,
        userName: userName,
      ),
    ]);
  }

  Future<void> reconcileCustom(
    String namespace,
    List<ReminderRequest> requests,
  ) => _reconcile(namespace, requests);

  Future<void> reconcileRoutine(Routine routine, {DateTime? now}) async {
    _routines = [
      for (final existing in _routines)
        if (existing.id != routine.id) existing,
      routine,
    ];
    final namespace = 'routine:${routine.id}';
    if (!routine.reminderEnabled || routine.time == null) {
      await cancelNamespace(namespace);
      return;
    }

    final current = now ?? DateTime.now();
    final days = routine.selectedDays == null || routine.selectedDays!.isEmpty
        ? const [0, 1, 2, 3, 4, 5, 6]
        : routine.selectedDays!;
    final requests = <ReminderRequest>[];

    for (final day in days) {
      final targetWeekday = day + 1;
      final daysUntil = (targetWeekday - current.weekday) % 7;
      var scheduled = DateTime(
        current.year,
        current.month,
        current.day + daysUntil,
        routine.time!.hour,
        routine.time!.minute,
      ).subtract(Duration(minutes: routine.reminderMinutesBefore));
      if (!scheduled.isAfter(current)) {
        scheduled = scheduled.add(const Duration(days: 7));
      }
      requests.add(
        ReminderRequest(
          logicalKey: '$namespace:weekday:$day',
          namespace: namespace,
          title: routine.name,
          body: routine.reminderMinutesBefore == 0
              ? 'Your routine is ready to begin.'
              : 'Starts in ${routine.reminderMinutesBefore} minutes.',
          payload: 'kora://routine/${routine.id}',
          scheduledAt: scheduled,
          repeat: ReminderRepeat.weekly,
        ),
      );
    }
    await _reconcile(namespace, requests);
  }

  Future<void> reconcileRoutines(Iterable<Routine> routines) async {
    _routines = routines.toList(growable: false);
    final existing = await _idRegistry.entriesForNamespace('routine');
    final desiredNamespaces = routines.map(
      (routine) => 'routine:${routine.id}',
    );
    final desiredPrefixes = desiredNamespaces.map((value) => '$value:').toSet();
    final staleKeys = existing.keys.where(
      (key) => !desiredPrefixes.any(key.startsWith),
    );
    for (final key in staleKeys) {
      await _notifications.cancelNotification(existing[key]!);
    }
    await _idRegistry.removeKeys(staleKeys);
    for (final routine in routines) {
      await reconcileRoutine(routine);
    }
  }

  Future<void> removeRoutine(String routineId) async {
    _routines = _routines
        .where((routine) => routine.id != routineId)
        .toList(growable: false);
    await cancelNamespace('routine:$routineId');
  }

  Future<void> reconcileCalendarEvent(CalendarEvent event) async {
    _calendarEvents = [
      for (final existing in _calendarEvents)
        if (existing.id != event.id) existing,
      event,
    ];
    final namespace = 'calendar:${event.id}';
    if (!event.hasReminder || event.isCompleted || event.isPast) {
      await cancelNamespace(namespace);
      return;
    }
    await _reconcile(namespace, [
      ReminderRequest(
        logicalKey: '$namespace:event',
        namespace: namespace,
        title: event.title,
        body: event.description ?? 'Your event is coming up.',
        payload: 'kora://calendar/${event.id}',
        scheduledAt: event.notificationTime,
        exact: true,
      ),
    ]);
  }

  Future<void> reconcileCalendarEvents(Iterable<CalendarEvent> events) async {
    _calendarEvents = events.toList(growable: false);
    final existing = await _idRegistry.entriesForNamespace('calendar');
    final desiredNamespaces = events.map((event) => 'calendar:${event.id}');
    final desiredPrefixes = desiredNamespaces.map((value) => '$value:').toSet();
    final staleKeys = existing.keys.where(
      (key) => !desiredPrefixes.any(key.startsWith),
    );
    for (final key in staleKeys) {
      await _notifications.cancelNotification(existing[key]!);
    }
    await _idRegistry.removeKeys(staleKeys);
    for (final event in events) {
      await reconcileCalendarEvent(event);
    }
  }

  Future<void> removeCalendarEvent(String eventId) async {
    _calendarEvents = _calendarEvents
        .where((event) => event.id != eventId)
        .toList(growable: false);
    await cancelNamespace('calendar:$eventId');
  }

  Future<void> cancelNamespace(String namespace) => _reconcile(namespace, []);

  Future<void> cancelAllOwned() async {
    for (final feature in ReminderFeature.values) {
      await cancelNamespace(feature.namespace);
    }
    await cancelNamespace('routine');
    await cancelNamespace('calendar');
  }

  Future<void> reconcileAllCached() async {
    await reconcileRoutines(_routines);
    await reconcileCalendarEvents(_calendarEvents);
    await reconcileWater(goalReached: _waterGoalReached);
    for (final feature in _dailyStates.keys) {
      await _reconcileCachedFeature(feature);
    }
    await reconcileWeeklyInsight(
      insight: _weeklyInsight,
      userName: _weeklyInsightUserName,
    );
  }

  Future<void> _reconcileCachedFeature(ReminderFeature feature) async {
    if (feature == ReminderFeature.water) {
      await reconcileWater(goalReached: _waterGoalReached);
      return;
    }
    if (feature == ReminderFeature.weeklyInsights) {
      await reconcileWeeklyInsight(
        insight: _weeklyInsight,
        userName: _weeklyInsightUserName,
      );
      return;
    }
    final state = _dailyStates[feature];
    if (state == null) return;
    await reconcileDailyFeature(
      feature: feature,
      completedToday: state.completedToday,
      actionable: state.actionable,
      title: state.title,
      body: state.body,
      payload: state.payload,
    );
  }

  Future<void> _reconcile(
    String namespace,
    List<ReminderRequest> desired,
  ) async {
    final permission = await refreshPermissionState();
    final canSchedule =
        _preferences.masterEnabled &&
        permission == NotificationPermissionState.granted;
    final requests = canSchedule ? desired : const <ReminderRequest>[];
    final existing = await _idRegistry.entriesForNamespace(namespace);
    final desiredKeys = requests.map((request) => request.logicalKey).toSet();

    final stale = existing.entries.where(
      (entry) => !desiredKeys.contains(entry.key),
    );
    for (final entry in stale) {
      await _notifications.cancelNotification(entry.value);
    }
    await _idRegistry.removeKeys(stale.map((entry) => entry.key));

    for (final request in requests) {
      final id = await _idRegistry.idFor(request.logicalKey);
      await _notifications.scheduleReminder(id, request);
    }
  }
}
