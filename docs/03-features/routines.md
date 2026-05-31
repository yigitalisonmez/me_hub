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
- `RoutineItem` uses `typeId: 10`. The previous conflict with `AffirmationSession`
  is resolved — that model moved to `typeId: 12`. See `02-architecture/hive-typeids.md`.
- UI fully redesigned as part of Kora Redesign (2026-05-31).
