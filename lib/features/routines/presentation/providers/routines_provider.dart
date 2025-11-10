import 'package:flutter/foundation.dart';
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

  List<Routine> get routines => _routines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRoutines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _routines = await _getRoutines();
    } catch (e) {
      _error = 'Routines failed to load';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNewRoutine(String id, String name) async {
    final routine = Routine(
      id: id,
      name: name,
      items: const [],
      streakCount: 0,
    );
    await _addRoutine(routine);
    await loadRoutines();
  }

  Future<void> addItem(String routineId, RoutineItem item) async {
    final index = _routines.indexWhere((r) => r.id == routineId);
    if (index == -1) return;
    final routine = _routines[index];
    var updated = routine.copyWith(items: [...routine.items, item]);
    
    // Streak kontrolü yap
    updated = _checkAndUpdateStreak(routine, updated);
    
    await _updateRoutine(updated);
    await loadRoutines();
  }

  Future<void> deleteItem(String routineId, String itemId) async {
    final index = _routines.indexWhere((r) => r.id == routineId);
    if (index == -1) return;
    final routine = _routines[index];
    final updatedItems = routine.items.where((item) => item.id != itemId).toList();
    var updated = routine.copyWith(items: updatedItems);
    
    // Streak kontrolü yap
    updated = _checkAndUpdateStreak(routine, updated);
    
    await _updateRoutine(updated);
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
    await loadRoutines();
  }

  // Streak kontrol ve güncelleme helper metodu
  Routine _checkAndUpdateStreak(Routine originalRoutine, Routine updatedRoutine) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedYesterday = normalizedToday.subtract(const Duration(days: 1));

    // Tüm itemler bugün tamamlandı mı?
    final allItemsCheckedToday = updatedRoutine.allItemsCheckedToday(normalizedToday);

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
      final newStreak = originalRoutine.streakCount > 0 ? originalRoutine.streakCount - 1 : 0;
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
