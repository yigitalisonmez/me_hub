# Feature: Insights (Consistency + Weekly Wrapped + Quick Log)

## Purpose

Cross-feature reflection surfaces from the Kora Redesign board (section 6):
a GitHub-style consistency heatmap, a story-format weekly recap, and a
one-tap quick-log sheet on Home.

## Code Roots

- `lib/features/insights/domain/` — `ConsistencyCalculator` (pure),
  `ConsistencySummary`, `WeeklyWrappedData`
- `lib/features/insights/data/services/insights_data_service.dart`
- `lib/features/insights/presentation/pages/consistency_page.dart`
- `lib/features/insights/presentation/pages/weekly_wrapped_page.dart`
- `lib/features/home/presentation/widgets/quick_log_sheet.dart`

## Data

`InsightsDataService` is **read-only** over existing stores; it never writes:

- `todos` Hive box (completed tasks per day)
- `water_intake` Hive box (ml per day)
- `mood_entries` Hive box (score per day)
- `gratitude_entries` Hive box (entries per day)
- `breathing_session_history` / `affirmation_session_history`
  SharedPreferences JSON (mindful sessions per day)

A day's "habits completed" is the count of those five categories active that
day (0–5, heatmap level caps at 4). Current streak tolerates an empty "today"
(the streak breaks only after the day ends).

Weekly Wrapped covers the current Mon–Sun week when opened on Sunday
(matching the Sunday Home banner), otherwise the previous full week.

## Entry Points

- Explore → Insights → Consistency / Weekly wrapped (Home explore section).
- Profile → Day streak stat card → Consistency.
- Home → Sunday-only gradient banner → Weekly wrapped.
- Home → floating "Quick log" pill above the navbar → quick-log sheet.

## Quick Log

The sheet only *adds* (water stepper floor is today's logged glasses), maps
five mood buckets to scores 2/4/6/8/10 via existing `MoodUtils`, and toggles
the first three tasks. Everything persists through the existing Water, Mood,
and Todo providers on "Log everything".

## Notes

- Wrapped's share action uses `share_plus` (plain text summary, no assets).
- Copy on all wrapped slides degrades gracefully for empty weeks; no fake
  stats (the design's "top 8% of Kora" claim was intentionally dropped —
  the app has no backend to know that).
- Tests: `test/features/insights/consistency_calculator_test.dart`.
