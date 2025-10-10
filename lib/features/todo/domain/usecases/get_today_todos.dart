import '../entities/daily_todo.dart';
import '../repositories/todo_repository.dart';
import '../../../../core/utils/result.dart';

/// Bugünkü todo'ları getirme use case'i
class GetTodayTodos {
  final TodoRepository repository;

  GetTodayTodos(this.repository);

  Future<Result<List<DailyTodo>>> call() async {
    return await repository.getTodayTodos();
  }
}
