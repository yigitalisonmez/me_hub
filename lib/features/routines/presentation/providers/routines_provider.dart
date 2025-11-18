import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/routine.dart';
import '../../domain/usecases/usecases.dart';

class RoutinesProvider with ChangeNotifier {
  final GetRoutines _getRoutines;
  final AddRoutine _addRoutine;
  final UpdateRoutine _updateRoutine;
  final DeleteRoutine _deleteRoutine;

  RoutinesProvider({
    required GetRoutines getRoutines,
    required AddRoutine addRoutine,
    required UpdateRoutine updateRoutine,
    required DeleteRoutine deleteRoutine,
  }) : _getRoutines = getRoutines,
       _addRoutine = addRoutine,
       _updateRoutine = updateRoutine,
       _deleteRoutine = deleteRoutine;

  List<Routine> _routines = [];
  bool _isLoading = false;
  String? _error;
  final Set<String> _expandedRoutines = {};
  String? _justCompletedRoutineName;

  List<Routine> get routines => _routines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get the name of the routine that was just completed (for celebration)
  String? get justCompletedRoutineName {
    final result = _justCompletedRoutineName;
    _justCompletedRoutineName = null; // Reset after reading
    return result;
  }

  /// Check if a routine is expanded
  bool isRoutineExpanded(String routineId) => _expandedRoutines.contains(routineId);

  /// Toggle routine expansion
  void toggleRoutineExpansion(String routineId) {
    if (_expandedRoutines.contains(routineId)) {
      _expandedRoutines.remove(routineId);
    } else {
      _expandedRoutines.add(routineId);
    }
    notifyListeners();
  }

  Future<void> loadRoutines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _routines = await _getRoutines();

      // Her routine için streak reset kontrolü yap
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      bool needsUpdate = false;
      for (int i = 0; i < _routines.length; i++) {
        final routine = _routines[i];
        final updatedRoutine = _checkStreakReset(routine, normalizedToday);
        if (updatedRoutine != routine) {
          _routines[i] = updatedRoutine;
          await _updateRoutine(updatedRoutine);
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        // Eğer bir güncelleme yapıldıysa, tekrar yükle
        _routines = await _getRoutines();
      }
    } catch (e) {
      _error = 'Routines failed to load';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNewRoutine(
    String name, {
    int? iconCodePoint,
    TimeOfDay? time,
    List<int>? selectedDays,
  }) async {
    final routine = Routine(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      items: const [],
      streakCount: 0,
      iconCodePoint: iconCodePoint,
      timeHour: time?.hour,
      timeMinute: time?.minute,
      selectedDays: selectedDays,
    );
    await _addRoutine(routine);
    await loadRoutines();
  }

  /// Get routines active on a specific weekday
  /// weekday: 0=Monday, 6=Sunday
  List<Routine> getActiveRoutinesForDay(int weekday) {
    return _routines.where((routine) => routine.isActiveOnDay(weekday)).toList();
  }

  /// Get routine by ID, returns null if not found
  Routine? getRoutineById(String routineId) {
    try {
      return _routines.firstWhere((r) => r.id == routineId);
    } catch (e) {
      return null;
    }
  }

  Future<void> addItem(String routineId, RoutineItem item) async {
    final index = _routines.indexWhere((r) => r.id == routineId);
    if (index == -1) return;
    final routine = _routines[index];
    var updated = routine.copyWith(items: [...routine.items, item]);

    // Streak kontrolü yap
    updated = _checkAndUpdateStreak(routine, updated);

    await _updateRoutine(updated);

    // Update local state immediately for UI responsiveness
    _routines[index] = updated;
    notifyListeners();

    // Then reload from storage to ensure consistency
    await loadRoutines();
  }

  Future<void> deleteItem(String routineId, String itemId) async {
    try {
      final index = _routines.indexWhere((r) => r.id == routineId);
      if (index == -1) {
        debugPrint('deleteItem: Routine not found: $routineId');
        return;
      }

      final routine = _routines[index];
      final itemCountBefore = routine.items.length;
      final updatedItems = routine.items
          .where((item) => item.id != itemId)
          .toList();

      if (updatedItems.length == itemCountBefore) {
        // Item bulunamadı, silinecek bir şey yok
        debugPrint(
          'deleteItem: Item not found: $itemId in routine: $routineId',
        );
        return;
      }

      var updated = routine.copyWith(items: updatedItems);

      // Streak kontrolü yap
      updated = _checkAndUpdateStreak(routine, updated);

      debugPrint(
        'deleteItem: Before _updateRoutine - routine has ${updated.items.length} items',
      );

      // Update storage first
      final result = await _updateRoutine(updated);
      debugPrint(
        'deleteItem: After _updateRoutine - result has ${result.items.length} items',
      );

      // Then update local state
      _routines[index] = updated;
      notifyListeners();

      debugPrint(
        'deleteItem: Successfully deleted item $itemId from routine $routineId',
      );
      debugPrint(
        'deleteItem: Local state updated - _routines[$index] has ${_routines[index].items.length} items',
      );
    } catch (e, stackTrace) {
      debugPrint('deleteItem error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> editItem(
    String routineId,
    String itemId, {
    String? title,
    int? iconCodePoint,
  }) async {
    final index = _routines.indexWhere((r) => r.id == routineId);
    if (index == -1) return;

    final routine = _routines[index];
    final updatedItems = routine.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          title: title ?? item.title,
          iconCodePoint: iconCodePoint,
        );
      }
      return item;
    }).toList();

    final updated = routine.copyWith(items: updatedItems);
    await _updateRoutine(updated);

    // Update local state immediately for UI responsiveness
    _routines[index] = updated;
    notifyListeners();

    // Then reload from storage to ensure consistency
    await loadRoutines();
  }

  Future<void> toggleItemCheckedToday(String routineId, String itemId) async {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    final index = _routines.indexWhere((r) => r.id == routineId);
    if (index == -1) return;

    final routine = _routines[index];

    // Tıklanan item'ın index'ini bul
    final itemIndex = routine.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    // Item'ı toggle et
    final targetItem = routine.items[itemIndex];
    final isCurrentlyChecked = targetItem.isCheckedToday(normalizedToday);

    final updatedItems = routine.items.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;

      if (idx == itemIndex) {
        // Tıklanan item'ı toggle et
        return item.copyWith(
          lastCheckedDate: isCurrentlyChecked ? null : normalizedToday,
        );
      } else if (idx > itemIndex && isCurrentlyChecked) {
        // Eğer bir item undo ediliyorsa (checked -> unchecked),
        // ondan sonraki tüm tamamlanmış itemları da undo et
        return item.copyWith(lastCheckedDate: null);
      } else {
        return item;
      }
    }).toList();

    var updatedRoutine = routine.copyWith(items: updatedItems);

    // Check if routine was just completed
    final wasCompletedBefore = routine.allItemsCheckedToday(normalizedToday);
    final isCompletedNow = updatedRoutine.allItemsCheckedToday(normalizedToday);
    
    if (!wasCompletedBefore && isCompletedNow && updatedRoutine.items.isNotEmpty) {
      _justCompletedRoutineName = updatedRoutine.name;
    }

    // Streak kontrolü yap
    updatedRoutine = _checkAndUpdateStreak(routine, updatedRoutine);

    await _updateRoutine(updatedRoutine);
    await loadRoutines();
  }

  Future<void> deleteRoutine(String routineId) async {
    await _deleteRoutine(routineId);
    await loadRoutines();
  }

  Future<void> updateRoutine(Routine routine) async {
    await _updateRoutine(routine);

    // Update local state immediately for UI responsiveness
    final index = _routines.indexWhere((r) => r.id == routine.id);
    if (index != -1) {
      _routines[index] = routine;
      notifyListeners();
    }

    // Then reload from storage to ensure consistency
    await loadRoutines();
  }

  /// Update routine name with validation
  /// Returns error message if validation fails, null if successful
  Future<String?> updateRoutineName(String routineId, String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Routine name cannot be empty';
    }

    final index = _routines.indexWhere((r) => r.id == routineId);
    if (index == -1) {
      return 'Routine not found';
    }

    final currentRoutine = _routines[index];
    final updatedRoutine = currentRoutine.copyWith(name: trimmedName);

    await updateRoutine(updatedRoutine);
    return null; // Success
  }

  /// Create a new RoutineItem with generated ID
  RoutineItem createRoutineItem({
    required String title,
    int? iconCodePoint,
  }) {
    return RoutineItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      iconCodePoint: iconCodePoint,
    );
  }

  Future<void> reorderItems(
    String routineId,
    int oldIndex,
    int newIndex,
  ) async {
    final index = _routines.indexWhere((r) => r.id == routineId);
    if (index == -1) return;

    final routine = _routines[index];
    final items = List<RoutineItem>.from(routine.items);

    // Reorder the items
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    // Update the routine with new order
    final updated = routine.copyWith(items: items);
    await _updateRoutine(updated);

    // Update local state immediately for UI responsiveness
    _routines[index] = updated;
    notifyListeners();

    // Then reload from storage to ensure consistency
    await loadRoutines();
  }

  // Streak reset kontrolü - bir gün routine yapılmazsa streak sıfırlanır
  Routine _checkStreakReset(Routine routine, DateTime normalizedToday) {
    // Eğer streak yoksa veya bugün tamamlanmışsa, bir şey yapma
    if (routine.streakCount == 0 || routine.lastStreakDate == null) {
      return routine;
    }

    final lastStreakDate = routine.lastStreakDate!;
    final lastStreakDateNorm = DateTime(
      lastStreakDate.year,
      lastStreakDate.month,
      lastStreakDate.day,
    );

    // Eğer lastStreakDate bugünse, streak devam ediyor
    if (lastStreakDateNorm == normalizedToday) {
      return routine;
    }

    // Eğer lastStreakDate bugünden önceki bir günse ve bugün tamamlanmamışsa
    // streak sıfırlanmalı
    final allItemsCheckedToday = routine.allItemsCheckedToday(normalizedToday);

    if (!allItemsCheckedToday) {
      // Bugün tamamlanmamış → streak sıfırla
      return routine.copyWith(streakCount: 0, clearLastStreakDate: true);
    }

    return routine;
  }

  // Streak kontrol ve güncelleme helper metodu
  Routine _checkAndUpdateStreak(
    Routine originalRoutine,
    Routine updatedRoutine,
  ) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedYesterday = normalizedToday.subtract(
      const Duration(days: 1),
    );

    // Tüm itemler bugün tamamlandı mı?
    final allItemsCheckedToday = updatedRoutine.allItemsCheckedToday(
      normalizedToday,
    );

    // Bugün için streak sayılmış mı?
    final lastStreakDate = originalRoutine.lastStreakDate;
    final lastStreakDateNorm = lastStreakDate == null
        ? null
        : DateTime(
            lastStreakDate.year,
            lastStreakDate.month,
            lastStreakDate.day,
          );
    final isStreakIncremented = lastStreakDateNorm == normalizedToday;

    // Streak güncelleme mantığı
    if (allItemsCheckedToday && !isStreakIncremented) {
      // Tüm itemler tamamlandı VE bugün henüz sayılmamış
      int newStreak;
      if (lastStreakDateNorm == normalizedYesterday) {
        // Dün de tamamlanmış → Streak devam ediyor
        newStreak = originalRoutine.streakCount + 1;
      } else {
        // Dün tamamlanmamış → Yeni streak başlıyor
        newStreak = 1;
      }
      return updatedRoutine.copyWith(
        streakCount: newStreak,
        lastStreakDate: normalizedToday,
      );
    } else if (!allItemsCheckedToday && isStreakIncremented) {
      // Tüm itemler tamamlanmamış AMA bugün için streak sayılmıştı → Geri al
      final newStreak = originalRoutine.streakCount > 0
          ? originalRoutine.streakCount - 1
          : 0;
      // Streak 0'a düşmüşse null, değilse önceki gün (dün)
      if (newStreak > 0) {
        return updatedRoutine.copyWith(
          streakCount: newStreak,
          lastStreakDate: normalizedYesterday,
        );
      } else {
        return updatedRoutine.copyWith(
          streakCount: newStreak,
          clearLastStreakDate: true,
        );
      }
    }

    return updatedRoutine;
  }
}
