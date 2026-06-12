# Feature Reminder Plan

Status: Implemented

Date: 2026-06-08

Implemented: 2026-06-08

## Goal

Add honest, persisted reminder controls at both global and feature level.
Reminders must survive app restarts, cancel cleanly, respect system permission
state, and never appear enabled when the operating system has blocked them.

This plan expands the existing Routine, Calendar, and weekly insight scheduling
instead of introducing a second notification stack.

## Current State

- `NotificationService` schedules Routine, Calendar, and weekly insight
  notifications.
- Calendar persists `hasReminder` and `reminderOffset`.
- Routine creation has a reminder switch, but that choice is not persisted.
  Any routine with a time can be scheduled again on the next app start.
- Notification and exact-alarm permissions are requested during app startup.
- Notification taps have no navigation behavior.
- Routine and Calendar IDs are derived from `String.hashCode`; this is not a
  durable ID contract.
- Routine startup reconciliation cannot cancel notifications that belong to a
  routine which was deleted outside the current in-memory list.
- The project is locked to `flutter_local_notifications 17.2.4`. A package
  major-version upgrade is separate work and should not be bundled into this
  feature unless a required API is missing.

## Product Rules

1. New reminder types are opt-in and default to disabled.
2. Enabling the first reminder is the moment to explain and request system
   notification permission. App startup must not show a permission prompt.
3. A global `Reminders` switch gates all Kora schedules.
4. Turning the global switch off cancels scheduled notifications but preserves
   each feature's saved preferences.
5. Re-enabling the global switch restores schedules from persisted settings.
6. A system-denied permission is displayed as `Blocked by system`, with an
   action to open app notification settings.
7. Wellness reminders use `inexactAllowWhileIdle`. Exact alarms are not needed
   for Water, Mood, Gratitude, Breathing, Affirmations, Todo, Challenges, or
   weekly insights.
8. Calendar may retain exact delivery only after an explicit permission and
   release-policy review. It must always have an inexact fallback.
9. Completing a feature's daily action cancels its remaining reminders for
   today without disabling future days.
10. Deleting or undoing completion restores a future reminder for today when
    the configured time has not passed.
11. Notification copy uses the app's current English UI language and avoids
    claims that cannot be computed from persisted data.

## Reminder Matrix

| Feature | Control | Schedule | Suppression rule | Destination |
| --- | --- | --- | --- | --- |
| Routines | Per routine toggle and lead time | Selected weekdays, default 5 minutes before | Cancel when disabled, time removed, or routine deleted | Routine detail |
| Calendar | Existing per-event toggle and offset | One notification before event | Cancel when completed, disabled, past, or deleted | Calendar event/day |
| Water | Toggle, active window, interval | Every 2, 3, or 4 hours inside the window | Pause remaining slots after daily goal; restore after undo below goal | Water |
| Mood | Toggle and daily time | Once daily | Skip after today's mood is saved | Mood |
| Gratitude | Separate morning/evening toggles and times | Up to twice daily | Skip the completed entry type | Gratitude entry |
| Breathing | Toggle and daily time | Once daily | Skip after a completed breathing session today | Breathing |
| Affirmations | Toggle and daily time | Once daily | Skip after a completed session today | Affirmations |
| Todo | Toggle and review time | One-shot reminders for days with incomplete tasks | Skip when no incomplete tasks remain | Todo |
| Challenges | Toggle and check-in time | Once daily while an active challenge/goal exists | Skip after today's active check-ins are complete | Challenges |
| Weekly insights | Toggle, fixed Sunday 20:00 in v1 | Weekly, refreshed on app open | Cancel when disabled or data is insufficient | Home insights |

Timer completion alerts are not part of this reminder preference system. Home,
Profile, Settings, Voice, and Onboarding are destinations or shells rather than
independent reminder sources.

## Persisted Model

Use SharedPreferences through a typed repository. Do not read or write raw keys
from widgets.

Suggested files:

```text
lib/core/reminders/domain/reminder_feature.dart
lib/core/reminders/domain/reminder_preferences.dart
lib/core/reminders/data/reminder_preferences_repository.dart
lib/core/reminders/services/reminder_id_registry.dart
lib/core/reminders/services/reminder_schedule_planner.dart
lib/core/reminders/services/reminder_coordinator.dart
lib/core/reminders/presentation/reminder_settings_provider.dart
```

`ReminderPreferences` should be a versioned JSON document containing:

- `schemaVersion`
- `masterEnabled`
- one `enabled` flag per supported feature
- daily time for Mood, Breathing, Affirmations, Todo, and Challenges
- morning/evening settings for Gratitude
- start time, end time, and interval for Water
- weekly insight enabled state

Routine reminder state belongs on `Routine` because it is item-specific:

- `reminderEnabled`
- `reminderMinutesBefore`

Add new Hive fields without changing existing field numbers. Existing routines
with a time migrate to `reminderEnabled: true` to preserve current behavior.
Calendar already has persisted item-specific reminder fields.

## Scheduling Architecture

`NotificationService` remains the low-level platform gateway. It should expose
permission checks, schedule, cancel, pending-request, and app-settings methods.
It should not decide whether a user has completed a feature today.

`ReminderSchedulePlanner` is pure Dart. Given preferences, feature state, local
time, and timezone, it returns desired logical reminder requests.

`ReminderCoordinator` reconciles desired logical requests with pending platform
notifications:

```text
settings/data change
  -> feature provider or settings provider
  -> ReminderCoordinator.reconcile(feature)
  -> ReminderSchedulePlanner
  -> NotificationService schedule/cancel
```

Run a full reconciliation after storage and timezone initialization. Feature
providers request scoped reconciliation after meaningful changes such as:

- water add, undo, delete, or goal update
- mood save or delete
- gratitude save, edit, or delete
- todo add, update, completion, or delete
- routine/calendar create, update, completion, or delete
- breathing/affirmation session completion
- challenge join, check-in, goal creation, or completion

Full reconciliation must read lightweight persisted feature state through
repositories/status readers. It must not open feature pages or initialize
audio-heavy providers merely to decide whether a reminder is due.

Do not call `cancelAll()` during normal reconciliation because it would erase
unrelated Calendar, Routine, and insight schedules.

## Notification IDs

Replace runtime `String.hashCode` IDs with a persisted
`NotificationIdRegistry`.

- The logical key includes namespace and owner, for example
  `routine:<id>:weekday:1` or `water:slot:10:00`.
- The registry assigns a stable positive 31-bit integer and stores the mapping.
- Reconciliation cancels registry entries that are no longer in the desired
  schedule. This fixes stale notifications after deletion.
- Fixed singleton reminders such as weekly insights may retain a documented
  reserved ID.
- Tests must cover collision handling and namespace isolation.

## Repeating And Daily Completion

For daily reminders, schedule the next recurring occurrence. When the user
completes today's action:

1. Cancel that feature's recurring request.
2. Recreate it with its first occurrence tomorrow.
3. If completion is undone before today's time, recreate it starting today.

Todo reminders are data-driven rather than generic recurring notifications.
Schedule one-shot requests only for dates that already contain incomplete
tasks, then reconcile after Todo CRUD.

Water uses one recurring request for each slot inside its active window. The
minimum two-hour interval bounds notification volume and avoids an hourly
notification pattern. Reaching the goal shifts all slots to begin tomorrow.

Before scheduling, inspect pending requests and keep the total bounded,
especially on Apple platforms where pending local notifications are limited.
Calendar and Routine requests have priority over optional wellness reminders.

## Permission And Manifest Cleanup

Phase 0 must remove permission prompts from `NotificationService.initialize()`.
Initialization creates channels and callbacks only.

On the first user enable action:

1. Show Kora's short explanation.
2. Request `POST_NOTIFICATIONS` on Android 13+ or alert/sound permission on
   Apple platforms.
3. Persist settings only after recording the resulting state.
4. If denied, preserve the user's desired toggle but show it as blocked and do
   not schedule.

Audit `AndroidManifest.xml` during implementation:

- Keep `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, and `VIBRATE`.
- Remove unused foreground-service and battery-optimization permissions unless
  another implemented feature proves they are required.
- Remove `USE_EXACT_ALARM`.
- Keep `SCHEDULE_EXACT_ALARM` only if Calendar exact delivery remains in scope.
- Make the boot receiver configuration match the notification plugin's locked
  version and verify rescheduling after reboot.

## Settings UX

Add a `Reminders` section to Settings with:

- global master switch
- system permission status
- `Open system settings` action when blocked
- summary rows for each supported feature
- next scheduled reminder preview where practical

Use a dedicated `ReminderSettingsPage` for the full list. Keep detailed controls
near their owning feature as well:

- Routine create/edit owns its per-routine toggle and lead time.
- Calendar event form keeps its existing reminder offset.
- Water Goal/Settings owns interval and active window.
- Other feature rows can use compact time pickers on Reminder Settings.

All controls must read from the same provider; there must not be duplicate
preference state in individual pages.

## Notification Navigation

Add a typed payload, for example:

```text
kora://water
kora://mood
kora://routine/<id>
kora://calendar/<eventId>
```

Handle both a foreground tap and an app launch caused by a notification. Queue
the destination until `MaterialApp` navigation is ready, then open the existing
feature page through the app's established route helpers. Missing or deleted
owners fall back to the feature root rather than failing.

## Migration

On first launch with reminder schema v1:

1. Migrate routines with a saved time to reminders enabled at five minutes
   before start.
2. Keep Calendar `hasReminder` values unchanged.
3. Set all new feature reminders to disabled.
4. Set weekly insights to disabled and cancel legacy ID `9001` until the user
   explicitly enables it.
5. Set the global master to enabled only when a migrated Routine or Calendar
   reminder exists; otherwise leave it disabled.
6. Perform one documented migration-only `cancelAll()`, then rebuild every
   desired Routine, Calendar, and feature schedule through the stable registry.
   This is required because IDs belonging to already-deleted legacy objects
   cannot be discovered reliably. Normal reconciliation must never use
   `cancelAll()`.

The migration must be idempotent and covered by tests.

## Delivery Phases

### Phase 0: Baseline Safety

- Add plugin gateway tests using an injected/fake notification plugin.
- Remove startup permission prompts.
- Add permission-state APIs.
- Introduce stable ID registry and scoped reconciliation.
- Fix stale Routine notification cleanup.
- Audit manifest permissions.

### Phase 1: Persisted Controls

- Add preferences repository and provider.
- Add Settings section and dedicated Reminder Settings page.
- Add global enable/disable behavior.
- Persist Routine toggle and lead time.
- Route Calendar and Routine schedules through the coordinator.

### Phase 2: Water

- Add Water reminder toggle, interval, and active window.
- Reconcile after water/goal mutations.
- Suppress remaining slots after reaching the daily goal.
- Verify interval behavior across midnight and timezone changes.

### Phase 3: Simple Daily Features

- Add Mood.
- Add morning/evening Gratitude.
- Add Breathing.
- Add Affirmations.
- Connect completion and undo/delete suppression.

### Phase 4: Data-Conditional Features

- Add Todo reminders only for dates with incomplete tasks.
- Add Challenges reminders only while actionable progress exists.
- Add the explicit weekly insight toggle.

### Phase 5: Navigation And Device Verification

- Add typed notification payload navigation.
- Verify cold-start and background taps.
- Verify reboot, timezone change, daylight-saving change, permission denial,
  system-level disable, and app update behavior.
- Verify pending notification volume with many routines and calendar events.

## Test Plan

Unit tests:

- preference defaults, serialization, and migration
- next daily/weekly occurrence in multiple timezones
- Water slots across active-window and midnight boundaries
- completion suppression and undo restoration
- stable ID allocation, collision handling, and stale-key cleanup
- global and feature namespace reconciliation
- Calendar offset and Routine lead-time calculation

Provider/integration tests:

- settings survive provider recreation
- denied permission never reports an active schedule
- master off cancels all owned schedules and master on restores them
- feature completion cancels only that feature's remaining reminder
- routine/calendar deletion removes pending notifications
- Todo/Challenge conditions produce no empty reminder

Widget tests:

- Settings permission states
- Water interval validation
- Routine persisted toggle
- Calendar existing reminder controls remain intact

Physical-device checks:

- Android 13+ permission grant and denial
- Android reboot rescheduling
- exact permission unavailable with inexact fallback
- notification tap from foreground, background, and terminated state
- timezone change
- iOS permission and pending-request behavior when iOS release work starts

## Acceptance Criteria

- No notification permission dialog appears on ordinary app startup.
- Every visible reminder control is persisted and backed by a real schedule.
- Global and per-feature switches survive restart.
- System-denied notifications are clearly shown as blocked.
- Completing a daily action prevents later reminders for that action today.
- Undoing completion restores a still-future reminder.
- Routine and Calendar edit/delete operations leave no stale notifications.
- Feature schedules never cancel another feature's notifications.
- Notification taps open the intended feature or a safe feature-root fallback.
- `flutter analyze` and the complete test suite pass.
- Android profile/release builds are verified on a physical device.

## External Constraints

- Android recommends inexact alarms for most use cases and reserves exact
  alarms for truly precise user-facing needs:
  https://developer.android.com/develop/background-work/services/alarms
- Android 13+ notification permission should be requested in context after a
  user action:
  https://developer.android.com/develop/ui/views/notifications/notification-permission
- Scheduling, permission, payload, and platform-limit behavior must be checked
  against the locked plugin documentation before implementation:
  https://pub.dev/packages/flutter_local_notifications
