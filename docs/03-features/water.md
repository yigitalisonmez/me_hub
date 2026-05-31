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

- Provider updates can affect cumulative stats and the home widget.
- Check `home_widget` behavior when changing today's progress.
- Live audit found a likely stats integrity issue: all-time water increments on
  add, while undo/delete paths should be checked because they do not obviously
  decrement cumulative stats.
