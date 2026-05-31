# Feature: Mood Tracker

## Purpose

Record mood entries, show today's mood, history, trends, and heatmap views.

## Code Roots

- `lib/features/mood_tracker/domain/`
- `lib/features/mood_tracker/data/`
- `lib/features/mood_tracker/presentation/`

## Storage

- Hive box: `mood_entries`
- Hive type ID: 30

## Notes

- Mood data is also used by analytics flows (home widget is disabled for v1).
- Be careful when changing date filtering.
- UI fully redesigned as part of Kora Redesign (2026-05-31).
