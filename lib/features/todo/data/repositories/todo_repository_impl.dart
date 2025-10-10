import '../../domain/entities/daily_todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/todo_local_datasource.dart';
import '../../../../core/utils/result.dart';

/// Todo repository implementation
class TodoRepositoryImpl implements TodoRepository {
  final TodoLocalDataSource localDataSource;

  TodoRepositoryImpl({required this.localDataSource});

  @override
  Future<Result<List<DailyTodo>>> getAllTodos() async {
    return await localDataSource.getAllTodos();
  }

  @override
  Future<Result<List<DailyTodo>>> getTodosByDate(DateTime date) async {
    return await localDataSource.getTodosByDate(date);
  }

  @override
  Future<Result<List<DailyTodo>>> getTodayTodos() async {
    return await localDataSource.getTodayTodos();
  }

  @override
  Future<Result<DailyTodo?>> getTodoById(String id) async {
    return await localDataSource.getTodoById(id);
  }

  @override
  Future<Result<DailyTodo>> addTodo(DailyTodo todo) async {
    return await localDataSource.addTodo(todo);
  }

  @override
  Future<Result<DailyTodo>> updateTodo(DailyTodo todo) async {
    return await localDataSource.updateTodo(todo);
  }

  @override
  Future<Result<void>> deleteTodo(String id) async {
    return await localDataSource.deleteTodo(id);
  }

  @override
  Future<Result<DailyTodo>> markTodoAsCompleted(String id) async {
    return await localDataSource.markTodoAsCompleted(id);
  }

  @override
  Future<Result<DailyTodo>> markTodoAsIncomplete(String id) async {
    return await localDataSource.markTodoAsIncomplete(id);
  }

  @override
  Future<Result<List<DailyTodo>>> getCompletedTodos() async {
    return await localDataSource.getCompletedTodos();
  }

  @override
  Future<Result<List<DailyTodo>>> getIncompleteTodos() async {
    return await localDataSource.getIncompleteTodos();
  }

  @override
  Future<Result<List<DailyTodo>>> getTodosByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await localDataSource.getTodosByDateRange(startDate, endDate);
  }

  @override
  Future<Result<List<DailyTodo>>> getTodosByPriority(int priority) async {
    return await localDataSource.getTodosByPriority(priority);
  }

  @override
  Future<Result<Map<String, dynamic>>> getTodoStats() async {
    return await localDataSource.getTodoStats();
  }

  @override
  Future<Result<void>> clearAllTodos() async {
    return await localDataSource.clearAllTodos();
  }
}
