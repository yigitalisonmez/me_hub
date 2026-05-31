# Feature: Affirmations

## Purpose

Record short affirmations, select background audio, run affirmation sessions, and
store session history.

## Code Roots

- `lib/features/affirmations/domain/`
- `lib/features/affirmations/data/`
- `lib/features/affirmations/presentation/`

## Storage

- Hive model: `AffirmationSession`
- SharedPreferences metadata for saved recordings/session history in provider
  flows.
- Audio files stored through path provider / recorder paths.

## Notes

- Hive `typeId` conflict with `RoutineItem` is resolved — `AffirmationSession`
  moved to `typeId: 12`. See `02-architecture/hive-typeids.md`.
- The active UI/provider stores recordings and session history in
  SharedPreferences plus local files. The data-layer Hive repository remains
  in the codebase but is unused; treat it as dead code until explicitly needed.
- UI fully redesigned as part of Kora Redesign (2026-05-31).
