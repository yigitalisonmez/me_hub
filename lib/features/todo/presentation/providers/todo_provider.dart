import 'package:flutter/foundation.dart';
import '../../domain/entities/daily_todo.dart';
import '../../domain/usecases/get_today_todos.dart';
import '../../domain/usecases/get_all_todos.dart';
import '../../domain/usecases/add_todo.dart';
import '../../domain/usecases/update_todo.dart';
import '../../domain/usecases/delete_todo.dart';
import '../../domain/usecases/toggle_todo_completion.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/services/completion_tracker_service.dart';

/// Todo state management provider
class TodoProvider with ChangeNotifier {
  final GetTodayTodos _getTodayTodos;
  final GetAllTodos _getAllTodos;
  final AddTodo _addTodo;
  final UpdateTodo _updateTodo;
  final DeleteTodo _deleteTodo;
  final ToggleTodoCompletion _toggleTodoCompletion;

  TodoProvider({
    required GetTodayTodos getTodayTodos,
    required GetAllTodos getAllTodos,
    required AddTodo addTodo,
    required UpdateTodo updateTodo,
    required DeleteTodo deleteTodo,
    required ToggleTodoCompletion toggleTodoCompletion,
  }) : _getTodayTodos = getTodayTodos,
       _getAllTodos = getAllTodos,
       _addTodo = addTodo,
       _updateTodo = updateTodo,
       _deleteTodo = deleteTodo,
       _toggleTodoCompletion = toggleTodoCompletion;

  // State
  List<DailyTodo> _todos = [];
  bool _isLoading = false;
  String? _error;
  bool _justCompletedAllTodos = false;

  // Getters
  List<DailyTodo> get todos => _todos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Check if all todos are completed
  bool get allTodosCompleted {
    if (_todos.isEmpty) return false;
    return _todos.every((todo) => todo.isCompleted);
  }

  /// Check if all todos just became completed (only true after toggle/delete)
  bool get justCompletedAllTodos => _justCompletedAllTodos;

  /// Reset the justCompletedAllTodos flag (call after showing celebration)
  void resetJustCompletedAllTodos() {
    _justCompletedAllTodos = false;
    notifyListeners();
  }

  List<DailyTodo> get completedTodos =>
      _todos.where((todo) => todo.isCompleted).toList();
  List<DailyTodo> get incompleteTodos =>
      _todos.where((todo) => !todo.isCompleted).toList();

  int get totalTodos => _todos.length;
  int get completedCount => completedTodos.length;
  int get incompleteCount => incompleteTodos.length;

  double get completionRate =>
      totalTodos > 0 ? (completedCount / totalTodos) : 0.0;

  /// Bugünkü todo'ları yükle
  Future<void> loadTodayTodos() async {
    _setLoading(true);
    _clearError();

    final result = await _getTodayTodos();
    _setLoading(false);

    if (result is Success) {
      _todos = result.data ?? [];
      notifyListeners();
    } else {
      _setError(result.errorMessage ?? 'Todo\'lar yüklenemedi');
    }
  }

  /// Tüm todo'ları yükle
  Future<void> loadAllTodos() async {
    _setLoading(true);
    _clearError();

    final result = await _getAllTodos();
    _setLoading(false);

    if (result is Success) {
      _todos = result.data ?? [];
      notifyListeners();
    } else {
      _setError(result.errorMessage ?? 'Todo\'lar yüklenemedi');
    }
  }

  /// Add new todo
  Future<bool> addTodo({
    required String title,
    DateTime? date,
    int priority = 2,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _addTodo(
      title: title,
      date: date ?? DateTime.now(),
      priority: priority,
    );

    _setLoading(false);

    if (result is Success) {
      if (result.data != null) {
        _todos.add(result.data!);
      }
      notifyListeners();
      return true;
    } else {
      _setError(result.errorMessage ?? 'Failed to add todo');
      return false;
    }
  }

  /// Todo güncelle
  Future<bool> updateTodo(DailyTodo todo) async {
    _setLoading(true);
    _clearError();

    final result = await _updateTodo(todo);
    _setLoading(false);

    if (result is Success) {
      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1 && result.data != null) {
        _todos[index] = result.data!;
        notifyListeners();
      }
      return true;
    } else {
      _setError(result.errorMessage ?? 'Todo güncellenemedi');
      return false;
    }
  }

  /// Todo sil
  Future<bool> deleteTodo(String id) async {
    _setLoading(true);
    _clearError();

    // Check if all todos were completed before deletion
    final wasAllCompleted = allTodosCompleted;

    final result = await _deleteTodo(id);
    _setLoading(false);

    if (result is Success) {
      _todos.removeWhere((todo) => todo.id == id);
      
      // Check if all todos are now completed (only if wasn't before and now is)
      if (!wasAllCompleted && allTodosCompleted && _todos.isNotEmpty) {
        _justCompletedAllTodos = true;
      } else {
        _justCompletedAllTodos = false;
      }
      
      notifyListeners();
      return true;
    } else {
      _setError(result.errorMessage ?? 'Todo silinemedi');
      return false;
    }
  }

  /// Todo tamamlama durumunu değiştir
  Future<bool> toggleTodoCompletion(String id) async {
    _setLoading(true);
    _clearError();

    // Check if all todos were completed before toggle
    final wasAllCompleted = allTodosCompleted;

    final result = await _toggleTodoCompletion(id);
    _setLoading(false);

    if (result is Success) {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1 && result.data != null) {
        _todos[index] = result.data!;
        
        // Check if all todos just became completed (wasn't before, but is now)
        if (!wasAllCompleted && allTodosCompleted && _todos.isNotEmpty) {
          _justCompletedAllTodos = true;
        } else {
          _justCompletedAllTodos = false;
        }
        
        notifyListeners();

        // Completion tracking
        await _checkCompletionStatus();
      }
      return true;
    } else {
      _setError(result.errorMessage ?? 'Todo durumu değiştirilemedi');
      return false;
    }
  }

  /// Todo'yu tamamlandı olarak işaretle
  Future<bool> markAsCompleted(String id) async {
    final todo = _todos.firstWhere((t) => t.id == id);
    final completedTodo = todo.markAsCompleted();
    return await updateTodo(completedTodo);
  }

  /// Todo'yu tamamlanmamış olarak işaretle
  Future<bool> markAsIncomplete(String id) async {
    final todo = _todos.firstWhere((t) => t.id == id);
    final incompleteTodo = todo.markAsIncomplete();
    return await updateTodo(incompleteTodo);
  }

  /// Hata temizle
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Loading durumunu ayarla
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Hata ayarla
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Hata temizle
  void _clearError() {
    _error = null;
  }

  /// Completion durumunu kontrol et
  Future<void> _checkCompletionStatus() async {
    try {
      final today = DateTime.now();
      final totalTodos = _todos.length;
      final completedTodos = completedCount;

      // Completion durumunu kaydet
      await CompletionTrackerService.saveDailyCompletion(
        today,
        totalTodos,
        completedTodos,
      );

      // Celebration gösterilmeli mi kontrol et
      // Completion tracking is done, but celebration is handled in UI
      await CompletionTrackerService.shouldShowCelebration(
        today,
        totalTodos,
        completedTodos,
      );
    } catch (e) {
      debugPrint('Completion check error: $e');
    }
  }

  /// Celebration gösterildi olarak işaretle
  Future<void> markCelebrationShown() async {
    try {
      final today = DateTime.now();
      await CompletionTrackerService.markCelebrationShownToday(today);
    } catch (e) {
      debugPrint('Celebration mark error: $e');
    }
  }
}
