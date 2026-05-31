import 'package:flutter_test/flutter_test.dart';
import 'package:me_hub/features/todo/domain/entities/daily_todo.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  DailyTodo buildTodo({
    String id = 'todo-1',
    String title = 'Test task',
    bool isCompleted = false,
    int priority = 2,
    DateTime? date,
  }) => DailyTodo(
    id: id,
    title: title,
    isCompleted: isCompleted,
    createdAt: DateTime(2026, 5, 30, 9),
    date: date ?? DateTime(2026, 5, 30),
    priority: priority,
  );

  // ---------------------------------------------------------------------------
  // markAsCompleted / markAsIncomplete
  // ---------------------------------------------------------------------------

  group('DailyTodo completion state', () {
    test('markAsCompleted sets isCompleted to true', () {
      final todo = buildTodo();
      expect(todo.isCompleted, isFalse);
      final completed = todo.markAsCompleted();
      expect(completed.isCompleted, isTrue);
    });

    test('markAsCompleted sets completedAt to a non-null value', () {
      final todo = buildTodo();
      final completed = todo.markAsCompleted();
      expect(completed.completedAt, isNotNull);
    });

    test('markAsCompleted preserves id and title', () {
      final todo = buildTodo(id: 'x', title: 'My task');
      final completed = todo.markAsCompleted();
      expect(completed.id, equals('x'));
      expect(completed.title, equals('My task'));
    });

    test('markAsIncomplete sets isCompleted to false', () {
      final todo = buildTodo(isCompleted: true);
      final incomplete = todo.markAsIncomplete();
      expect(incomplete.isCompleted, isFalse);
    });

    test('markAsIncomplete clears completedAt', () {
      final todo = buildTodo(isCompleted: true);
      final incomplete = todo.markAsIncomplete();
      expect(incomplete.completedAt, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  group('DailyTodo copyWith', () {
    test('copyWith preserves all unchanged fields', () {
      final original = buildTodo(id: 'orig', priority: 3);
      final copy = original.copyWith(title: 'Updated');
      expect(copy.id, equals('orig'));
      expect(copy.priority, equals(3));
      expect(copy.isCompleted, isFalse);
    });

    test('copyWith changes only the specified field', () {
      final original = buildTodo(priority: 1);
      final updated = original.copyWith(priority: 3);
      expect(updated.priority, equals(3));
      expect(updated.title, equals(original.title));
    });
  });

  // ---------------------------------------------------------------------------
  // Priority labels
  // ---------------------------------------------------------------------------

  group('DailyTodo priorityText', () {
    test('priority 1 → Low', () {
      expect(buildTodo(priority: 1).priorityText, equals('Low'));
    });

    test('priority 2 → Medium', () {
      expect(buildTodo(priority: 2).priorityText, equals('Medium'));
    });

    test('priority 3 → High', () {
      expect(buildTodo(priority: 3).priorityText, equals('High'));
    });

    test('unknown priority falls back to Medium', () {
      expect(buildTodo(priority: 99).priorityText, equals('Medium'));
    });
  });

  // ---------------------------------------------------------------------------
  // Date helpers (isToday / isPast / isFuture)
  // ---------------------------------------------------------------------------

  group('DailyTodo date helpers', () {
    test('today todo is neither past nor future', () {
      final now = DateTime.now();
      final today = buildTodo(date: DateTime(now.year, now.month, now.day));
      expect(today.isToday, isTrue);
      expect(today.isPast, isFalse);
      expect(today.isFuture, isFalse);
    });

    test('yesterday todo is past', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final past = buildTodo(
        date: DateTime(yesterday.year, yesterday.month, yesterday.day),
      );
      expect(past.isPast, isTrue);
      expect(past.isToday, isFalse);
    });

    test('tomorrow todo is future', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final future = buildTodo(
        date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
      );
      expect(future.isFuture, isTrue);
      expect(future.isToday, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------

  group('DailyTodo equality', () {
    test('two todos with the same id are equal', () {
      final a = buildTodo(id: 'same');
      final b = buildTodo(id: 'same', title: 'Different title');
      expect(a, equals(b));
    });

    test('two todos with different ids are not equal', () {
      final a = buildTodo(id: 'a');
      final b = buildTodo(id: 'b');
      expect(a, isNot(equals(b)));
    });
  });
}
