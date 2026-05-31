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

- Reminder scheduling touches `NotificationService`.
- Background notifications verified on physical device (2026-05-30).
- `flutter analyze` passes cleanly.
- UI fully redesigned as part of Kora Redesign (2026-05-31).
