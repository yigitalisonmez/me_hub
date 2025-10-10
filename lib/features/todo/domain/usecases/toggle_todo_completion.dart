import '../entities/daily_todo.dart';
import '../repositories/todo_repository.dart';
import '../../../../core/utils/result.dart';

/// Todo tamamlama durumunu değiştirme use case'i
class ToggleTodoCompletion {
  final TodoRepository repository;

  ToggleTodoCompletion(this.repository);

  Future<Result<DailyTodo>> call(String id) async {
    // Önce todo'yu getir
    final getResult = await repository.getTodoById(id);
    if (getResult is Error) {
      return Error(
        message: getResult.errorMessage ?? 'Todo getirilemedi',
        code: getResult.errorCode,
      );
    }

    final todo = getResult.data;
    if (todo == null) {
      return const Error(message: 'Todo bulunamadı');
    }

    // Tamamlama durumunu değiştir
    if (todo.isCompleted) {
      return await repository.markTodoAsIncomplete(id);
    } else {
      return await repository.markTodoAsCompleted(id);
    }
  }
}
