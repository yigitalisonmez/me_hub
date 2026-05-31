# Hive Type IDs

Hive adapter type IDs must be unique across all registered adapters.

## Known IDs

| Type ID | Type | File |
| --- | --- | --- |
| 0 | DailyTodo | `lib/features/todo/domain/entities/daily_todo.dart` |
| 1 | DailyTodoModel | `lib/features/todo/data/models/daily_todo_model.dart` |
| 10 | RoutineItem | `lib/features/routines/domain/entities/routine.dart` |
| 12 | AffirmationSession | `lib/features/affirmations/data/models/affirmation_session.dart` |
| 11 | Routine | `lib/features/routines/domain/entities/routine.dart` |
| 20 | WaterIntake | `lib/features/water/domain/entities/water_intake.dart` |
| 21 | WaterLog | `lib/features/water/domain/entities/water_intake.dart` |
| 30 | MoodEntry | `lib/features/mood_tracker/domain/entities/mood_entry.dart` |
| 40 | GratitudeEntry | `lib/features/gratitude/domain/entities/gratitude_entry.dart` |
| 41 | GratitudeItem | `lib/features/gratitude/domain/entities/gratitude_item.dart` |
| 42 | EntryType | `lib/features/gratitude/domain/entities/gratitude_entry.dart` |
| 50 | Challenge | `lib/features/challenges/domain/entities/challenge.dart` |
| 51 | GoalType | `lib/features/challenges/domain/entities/weekly_goal.dart` |
| 52 | BadgeRequirementType | `lib/features/challenges/domain/entities/badge.dart` |
| 53 | UserProgress | `lib/features/challenges/domain/entities/user_progress.dart` |
| 55 | ChallengeCategory | `lib/features/challenges/domain/entities/challenge.dart` |
| 56 | DailyProgress | `lib/features/challenges/domain/entities/challenge.dart` |
| 57 | WeeklyGoal | `lib/features/challenges/domain/entities/weekly_goal.dart` |
| 58 | Badge | `lib/features/challenges/domain/entities/badge.dart` |
| 59 | BadgeTier | `lib/features/challenges/domain/entities/badge.dart` |
| 60 | CalendarEvent | `lib/features/calendar/domain/entities/calendar_event.dart` |
| 61 | HiveReminderOffset | `lib/features/calendar/domain/entities/calendar_event.dart` |
| 62 | EventCategory | `lib/features/calendar/domain/entities/event_category.dart` |

## Resolved Conflicts

`typeId: 10` appeared in both `RoutineItem` and the original `AffirmationSession`.
This was resolved by moving `AffirmationSession` to `typeId: 12`. The repository
now guards registration with `if (!Hive.isAdapterRegistered(12))` to prevent
duplicate registration.

## Reserved Ranges

Use this convention for future work:

- 0-9: Todo and shared legacy models
- 10-19: Routines and affirmations legacy range, use with care
- 20-29: Water
- 30-39: Mood
- 40-49: Gratitude
- 50-59: Challenges
- 60-69: Calendar
- 70-79: Profile/settings
- 80-89: Analytics
- 90-99: Future platform integrations
