import '../entities/daily_todo.dart';
import '../repositories/todo_repository.dart';
import '../../../../core/utils/result.dart';

/// Tüm todo'ları getirme use case'i
class GetAllTodos {
  final TodoRepository repository;

  GetAllTodos(this.repository);

  Future<Result<List<DailyTodo>>> call() async {
    return await repository.getAllTodos();
  }
}
