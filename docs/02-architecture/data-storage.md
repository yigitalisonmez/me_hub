# Data Storage

Kora is local-first. Storage is split across Hive, SharedPreferences,
FlutterSecureStorage, and local audio files.

## Hive

Hive is used for structured feature data such as todos, routines, water entries,
mood entries, gratitude entries, challenges, and calendar events.

Known boxes include:

- `todos`
- `routines`
- `water_intake`
- `mood_entries`
- `gratitude_entries`
- `challenges`
- `weekly_goals`
- `badges`
- `user_progress`
- `calendar_events`
- `event_categories`
- `affirmation_sessions`

Verify exact names in each feature data source before changing storage logic.

## SharedPreferences

Used for:

- onboarding status
- theme settings
- voice settings
- quote cache
- cumulative stats
- completion tracking
- breathing settings/history in some flows
- affirmations recording/session metadata in some flows
- water quick-add settings and daily goal

## FlutterSecureStorage

Used for sensitive/simple user profile data such as `user_name`.

## Audio Files

Affirmations and breathing use audio recording/playback packages. When changing
these flows, check file path handling, permissions, disposal, and persistence.

## Change Checklist

- Update `hive-typeids.md` for any adapter/type changes.
- Do not manually edit generated adapters.
- Run build_runner after annotated model changes.
- Consider migration/backward compatibility for existing local user data.

## Live Audit Notes

- `RoutineItem` and data-layer `AffirmationSession` both use Hive `typeId: 10`.
- Current affirmation UI/provider stores recordings and session history through
  SharedPreferences/files, not the data-layer Hive repository path.
- `MoodLocalDataSource.init()` deletes and recreates `mood_entries` if opening
  the box fails. This can protect from old schema issues, but it is also a data
  loss risk if triggered unexpectedly.
- Water all-time stats are incremented when water is added. Undo/delete paths
  should be reviewed because they currently do not obviously decrement the
  cumulative profile stats.
