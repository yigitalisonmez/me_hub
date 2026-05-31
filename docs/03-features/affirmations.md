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

## Important Risk

`AffirmationSession` uses Hive `typeId: 10`, which conflicts with
`RoutineItem`. Resolve with a migration plan before registering both in the same
Hive runtime.

The active affirmation UI/provider currently stores saved recordings and session
history in SharedPreferences plus local files. The data-layer Hive repository
appears unused. Treat that path as dead/risky until proven otherwise.
