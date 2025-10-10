import '../entities/daily_todo.dart';
import '../repositories/todo_repository.dart';
import '../../../../core/utils/result.dart';

/// Todo güncelleme use case'i
class UpdateTodo {
  final TodoRepository repository;

  UpdateTodo(this.repository);

  Future<Result<DailyTodo>> call(DailyTodo todo) async {
    return await repository.updateTodo(todo);
  }
}
