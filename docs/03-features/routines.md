# Feature: Routines

## Purpose

Routine tracking with items, daily checks, streaks, selected days, icons, and
optional reminder times.

## Code Roots

- `lib/features/routines/domain/`
- `lib/features/routines/data/`
- `lib/features/routines/presentation/`

## Storage

- Box: `routines`
- Types: `RoutineItem`, `Routine`
- Hive type IDs: 10, 11

## Notes

- Notifications are scheduled from routine provider flows.
- `RoutineItem` uses `typeId: 10`, which currently conflicts with an
  affirmation model. Check `02-architecture/hive-typeids.md` before changing.
