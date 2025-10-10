import '../entities/daily_todo.dart';
import '../../../../core/utils/result.dart';

/// Todo repository interface'i
abstract class TodoRepository {
  /// Tüm todo'ları getir
  Future<Result<List<DailyTodo>>> getAllTodos();

  /// Belirli bir tarihteki todo'ları getir
  Future<Result<List<DailyTodo>>> getTodosByDate(DateTime date);

  /// Bugünkü todo'ları getir
  Future<Result<List<DailyTodo>>> getTodayTodos();

  /// Belirli bir todo'yu getir
  Future<Result<DailyTodo?>> getTodoById(String id);

  /// Yeni todo ekle
  Future<Result<DailyTodo>> addTodo(DailyTodo todo);

  /// Todo güncelle
  Future<Result<DailyTodo>> updateTodo(DailyTodo todo);

  /// Todo sil
  Future<Result<void>> deleteTodo(String id);

  /// Todo'yu tamamlandı olarak işaretle
  Future<Result<DailyTodo>> markTodoAsCompleted(String id);

  /// Todo'yu tamamlanmamış olarak işaretle
  Future<Result<DailyTodo>> markTodoAsIncomplete(String id);

  /// Tamamlanan todo'ları getir
  Future<Result<List<DailyTodo>>> getCompletedTodos();

  /// Tamamlanmamış todo'ları getir
  Future<Result<List<DailyTodo>>> getIncompleteTodos();

  /// Belirli bir tarih aralığındaki todo'ları getir
  Future<Result<List<DailyTodo>>> getTodosByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Belirli bir öncelik seviyesindeki todo'ları getir
  Future<Result<List<DailyTodo>>> getTodosByPriority(int priority);

  /// Todo istatistiklerini getir
  Future<Result<Map<String, dynamic>>> getTodoStats();

  /// Tüm todo'ları temizle
  Future<Result<void>> clearAllTodos();
}
