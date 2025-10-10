import 'package:hive_flutter/hive_flutter.dart';
import '../models/daily_todo_model.dart';
import '../../domain/entities/daily_todo.dart';
import '../../../../core/utils/result.dart';

/// Todo local data source (Hive)
abstract class TodoLocalDataSource {
  Future<Result<List<DailyTodo>>> getAllTodos();
  Future<Result<List<DailyTodo>>> getTodosByDate(DateTime date);
  Future<Result<List<DailyTodo>>> getTodayTodos();
  Future<Result<DailyTodo?>> getTodoById(String id);
  Future<Result<DailyTodo>> addTodo(DailyTodo todo);
  Future<Result<DailyTodo>> updateTodo(DailyTodo todo);
  Future<Result<void>> deleteTodo(String id);
  Future<Result<DailyTodo>> markTodoAsCompleted(String id);
  Future<Result<DailyTodo>> markTodoAsIncomplete(String id);
  Future<Result<List<DailyTodo>>> getCompletedTodos();
  Future<Result<List<DailyTodo>>> getIncompleteTodos();
  Future<Result<List<DailyTodo>>> getTodosByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Result<List<DailyTodo>>> getTodosByPriority(int priority);
  Future<Result<Map<String, dynamic>>> getTodoStats();
  Future<Result<void>> clearAllTodos();
}

class TodoLocalDataSourceImpl implements TodoLocalDataSource {
  static const String _boxName = 'todos';
  late Box<DailyTodoModel> _box;

  /// Hive box'unu başlat
  Future<void> init() async {
    _box = await Hive.openBox<DailyTodoModel>(_boxName);
  }

  /// Box'ı kapat
  Future<void> close() async {
    await _box.close();
  }

  @override
  Future<Result<List<DailyTodo>>> getAllTodos() async {
    try {
      final models = _box.values.toList();
      final entities = models.map((model) => model.toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return Error(message: 'Todo\'lar getirilemedi: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<DailyTodo>>> getTodosByDate(DateTime date) async {
    try {
      final models = _box.values.where((model) {
        final modelDate = model.date;
        return modelDate.year == date.year &&
            modelDate.month == date.month &&
            modelDate.day == date.day;
      }).toList();

      final entities = models.map((model) => model.toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return Error(
        message: 'Tarih bazlı todo\'lar getirilemedi: ${e.toString()}',
      );
    }
  }

  @override
  Future<Result<List<DailyTodo>>> getTodayTodos() async {
    final today = DateTime.now();
    return await getTodosByDate(today);
  }

  @override
  Future<Result<DailyTodo?>> getTodoById(String id) async {
    try {
      final model = _box.values.firstWhere(
        (model) => model.id == id,
        orElse: () => throw Exception('Todo bulunamadı'),
      );
      return Success(model.toEntity());
    } catch (e) {
      if (e.toString().contains('Todo bulunamadı')) {
        return const Success(null);
      }
      return Error(message: 'Todo getirilemedi: ${e.toString()}');
    }
  }

  @override
  Future<Result<DailyTodo>> addTodo(DailyTodo todo) async {
    try {
      final model = DailyTodoModel.fromEntity(todo);
      await _box.add(model);
      return Success(todo);
    } catch (e) {
      return Error(message: 'Todo eklenemedi: ${e.toString()}');
    }
  }

  @override
  Future<Result<DailyTodo>> updateTodo(DailyTodo todo) async {
    try {
      final index = _box.values.toList().indexWhere(
        (model) => model.id == todo.id,
      );
      if (index == -1) {
        return const Error(message: 'Todo bulunamadı');
      }

      final model = DailyTodoModel.fromEntity(todo);
      await _box.putAt(index, model);
      return Success(todo);
    } catch (e) {
      return Error(message: 'Todo güncellenemedi: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> deleteTodo(String id) async {
    try {
      final index = _box.values.toList().indexWhere((model) => model.id == id);
      if (index == -1) {
        return const Error(message: 'Todo bulunamadı');
      }

      await _box.deleteAt(index);
      return const Success(null);
    } catch (e) {
      return Error(message: 'Todo silinemedi: ${e.toString()}');
    }
  }

  @override
  Future<Result<DailyTodo>> markTodoAsCompleted(String id) async {
    try {
      final getResult = await getTodoById(id);
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

      final completedTodo = todo.markAsCompleted();
      final updateResult = await updateTodo(completedTodo);
      return updateResult;
    } catch (e) {
      return Error(message: 'Todo tamamlanamadı: ${e.toString()}');
    }
  }

  @override
  Future<Result<DailyTodo>> markTodoAsIncomplete(String id) async {
    try {
      final getResult = await getTodoById(id);
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

      final incompleteTodo = todo.markAsIncomplete();
      final updateResult = await updateTodo(incompleteTodo);
      return updateResult;
    } catch (e) {
      return Error(
        message: 'Todo tamamlanmamış olarak işaretlenemedi: ${e.toString()}',
      );
    }
  }

  @override
  Future<Result<List<DailyTodo>>> getCompletedTodos() async {
    try {
      final models = _box.values.where((model) => model.isCompleted).toList();
      final entities = models.map((model) => model.toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return Error(
        message: 'Tamamlanan todo\'lar getirilemedi: ${e.toString()}',
      );
    }
  }

  @override
  Future<Result<List<DailyTodo>>> getIncompleteTodos() async {
    try {
      final models = _box.values.where((model) => !model.isCompleted).toList();
      final entities = models.map((model) => model.toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return Error(
        message: 'Tamamlanmamış todo\'lar getirilemedi: ${e.toString()}',
      );
    }
  }

  @override
  Future<Result<List<DailyTodo>>> getTodosByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final models = _box.values.where((model) {
        final modelDate = model.date;
        return modelDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            modelDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      final entities = models.map((model) => model.toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return Error(
        message: 'Tarih aralığındaki todo\'lar getirilemedi: ${e.toString()}',
      );
    }
  }

  @override
  Future<Result<List<DailyTodo>>> getTodosByPriority(int priority) async {
    try {
      final models = _box.values
          .where((model) => model.priority == priority)
          .toList();
      final entities = models.map((model) => model.toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return Error(
        message: 'Öncelik bazlı todo\'lar getirilemedi: ${e.toString()}',
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getTodoStats() async {
    try {
      final allTodos = _box.values.toList();
      final total = allTodos.length;
      final completed = allTodos.where((todo) => todo.isCompleted).length;
      final incomplete = total - completed;
      final todayTodos = allTodos.where((todo) {
        final now = DateTime.now();
        return todo.date.year == now.year &&
            todo.date.month == now.month &&
            todo.date.day == now.day;
      }).length;

      return Success({
        'total': total,
        'completed': completed,
        'incomplete': incomplete,
        'today': todayTodos,
        'completionRate': total > 0 ? (completed / total * 100).round() : 0,
      });
    } catch (e) {
      return Error(
        message: 'Todo istatistikleri getirilemedi: ${e.toString()}',
      );
    }
  }

  @override
  Future<Result<void>> clearAllTodos() async {
    try {
      await _box.clear();
      return const Success(null);
    } catch (e) {
      return Error(message: 'Todo\'lar temizlenemedi: ${e.toString()}');
    }
  }
}
