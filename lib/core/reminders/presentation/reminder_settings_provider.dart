import 'package:flutter/foundation.dart';

import '../domain/reminder_feature.dart';
import '../domain/reminder_preferences.dart';
import '../services/reminder_coordinator.dart';
import '../../services/notification_service.dart';

class ReminderSettingsProvider with ChangeNotifier {
  final ReminderCoordinator _coordinator;

  bool _busy = false;

  ReminderSettingsProvider(this._coordinator);

  ReminderPreferences get preferences => _coordinator.preferences;
  NotificationPermissionState get permissionState =>
      _coordinator.permissionState;
  bool get busy => _busy;

  Future<bool> ensurePermission() => _ensurePermission();

  Future<bool> setMasterEnabled(bool enabled) async {
    final allowed = !enabled || await _ensurePermission();
    await _run(() => _coordinator.setMasterEnabled(enabled));
    return allowed;
  }

  Future<bool> setFeatureEnabled(ReminderFeature feature, bool enabled) async {
    final allowed = !enabled || await _ensurePermission();
    await _run(() async {
      if (enabled && !preferences.masterEnabled) {
        await _coordinator.setMasterEnabled(true);
      }
      await _coordinator.setFeatureEnabled(feature, enabled);
    });
    return allowed;
  }

  Future<void> setFeatureTime(
    ReminderFeature feature,
    ReminderTime time,
  ) async {
    await _run(() => _coordinator.setFeatureTime(feature, time));
  }

  Future<void> setWaterSettings({
    required ReminderTime start,
    required ReminderTime end,
    required int intervalHours,
  }) async {
    await _run(
      () => _coordinator.setWaterSettings(
        start: start,
        end: end,
        intervalHours: intervalHours,
      ),
    );
  }

  Future<void> refreshPermissionState() async {
    await _coordinator.refreshPermissionState();
    notifyListeners();
  }

  Future<void> openSystemSettings() => _coordinator.openSystemSettings();

  Future<bool> _ensurePermission() async {
    var state = await _coordinator.refreshPermissionState();
    if (state == NotificationPermissionState.granted) return true;
    state = await _coordinator.requestPermission();
    notifyListeners();
    return state == NotificationPermissionState.granted;
  }

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
