# Feature: Water

## Purpose

Track daily water intake, logs, daily goal, quick-add amounts, and home widget
updates.

## Code Roots

- `lib/features/water/domain/`
- `lib/features/water/data/`
- `lib/features/water/presentation/`

## Storage

- Hive box: `water_intake`
- SharedPreferences for daily goal and quick-add settings.
- Hive type IDs: 20, 21

## Notes

- Provider updates can affect cumulative stats (home widget disabled for v1).
- Stats integrity fixed: `undoLastLog()` and `deleteLog()` now both call
  `CumulativeStatsService.subtractWater()` (2026-05-30).
- `water_goal_page.dart` added as a dedicated goal-setting page.
- UI fully redesigned as part of Kora Redesign (2026-05-31).
- The main consumed-liter value rolls on initial display and when water logs
  change, using the shared animated metric widget.
