# Feature: Calendar

## Purpose

Events, categories, reminder offsets, completion state, and local notifications.

## Code Roots

- `lib/features/calendar/domain/`
- `lib/features/calendar/data/`
- `lib/features/calendar/presentation/`

## Storage

- Hive boxes: calendar events and event categories.
- Hive type IDs: 60, 61, 62.

## Notes

- Calendar files were untracked when this documentation structure was created.
- Reminder scheduling touches `NotificationService`.
- Analyzer currently reports async context and deprecated color value warnings in
  this feature.
- Treat Calendar as release-risky until reminder scheduling, update/delete
  cancellation, and Android notification permissions are verified on device.
