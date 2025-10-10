import '../repositories/todo_repository.dart';
import '../../../../core/utils/result.dart';

/// Todo silme use case'i
class DeleteTodo {
  final TodoRepository repository;

  DeleteTodo(this.repository);

  Future<Result<void>> call(String id) async {
    return await repository.deleteTodo(id);
  }
}
