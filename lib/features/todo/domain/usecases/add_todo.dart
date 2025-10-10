import '../entities/daily_todo.dart';
import '../repositories/todo_repository.dart';
import '../../../../core/utils/result.dart';

/// Todo ekleme use case'i
class AddTodo {
  final TodoRepository repository;

  AddTodo(this.repository);

  Future<Result<DailyTodo>> call({
    required String title,
    DateTime? date,
    int priority = 2,
  }) async {
    final todo = DailyTodo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      createdAt: DateTime.now(),
      date: date ?? DateTime.now(),
      priority: priority,
    );

    return await repository.addTodo(todo);
  }
}
