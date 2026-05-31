# Feature: Todo

## Purpose

Daily task tracking with completion state, priority, and today's list.

## Code Roots

- `lib/features/todo/domain/`
- `lib/features/todo/data/`
- `lib/features/todo/presentation/`

## Main Flow

```text
TodoPage/widgets -> TodoProvider -> UseCases -> TodoRepositoryImpl -> TodoLocalDataSource -> Hive
```

## Storage

- Box: `todos`
- Entity/model: `DailyTodo`, `DailyTodoModel`
- Hive type IDs: 0, 1

## Notes

- Completion updates cumulative stats.
- `test/widget_test.dart` is currently only a placeholder.
- Add provider/data-source tests when changing behavior.
