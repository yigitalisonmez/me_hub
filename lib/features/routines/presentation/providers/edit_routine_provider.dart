
import 'package:flutter/material.dart';
import '../../domain/entities/routine.dart';
import 'routines_provider.dart';

class EditRoutineProvider with ChangeNotifier {
  final RoutinesProvider _routinesProvider;
  final String routineId;

  EditRoutineProvider({
    required RoutinesProvider routinesProvider,
    required this.routineId,
  }) : _routinesProvider = routinesProvider {
    _initializeFromRoutine();
  }

  // Form state
  String _name = '';
  int? _selectedIconCodePoint;
  TimeOfDay? _selectedTime;
  List<int> _selectedDays = [];

  // Getters
  String get name => _name;
  int? get selectedIconCodePoint => _selectedIconCodePoint;
  TimeOfDay? get selectedTime => _selectedTime;
  List<int> get selectedDays => _selectedDays;

  // Get current routine
  Routine? get currentRoutine => _routinesProvider.getRoutineById(routineId);

  void _initializeFromRoutine() {
    final routine = currentRoutine;
    if (routine != null) {
      _name = routine.name;
      _selectedIconCodePoint = routine.iconCodePoint;
      _selectedTime = routine.time;
      _selectedDays = List<int>.from(routine.selectedDays ?? []);
      notifyListeners();
    }
  }

  // Update form fields
  void updateName(String name) {
    _name = name;
    notifyListeners();
  }

  void updateIconCodePoint(int? iconCodePoint) {
    _selectedIconCodePoint = iconCodePoint;
    notifyListeners();
  }

  void updateTime(TimeOfDay? time) {
    _selectedTime = time;
    notifyListeners();
  }

  void toggleDay(int dayIndex) {
    if (_selectedDays.contains(dayIndex)) {
      _selectedDays.remove(dayIndex);
    } else {
      _selectedDays.add(dayIndex);
    }
    notifyListeners();
  }

  // Save routine
  Future<void> saveRoutine() async {
    final routine = currentRoutine;
    if (routine == null) {
      debugPrint('Error: Routine not found: $routineId');
      return;
    }

    final updatedRoutine = routine.copyWith(
      name: _name.trim(),
      iconCodePoint: _selectedIconCodePoint,
      timeHour: _selectedTime?.hour,
      timeMinute: _selectedTime?.minute,
      selectedDays: _selectedDays,
    );

    await _routinesProvider.updateRoutine(updatedRoutine);
  }

  // Add item to routine
  Future<void> addItem(String title, int? iconCodePoint) async {
    final item = _routinesProvider.createRoutineItem(
      title: title,
      iconCodePoint: iconCodePoint,
    );
    await _routinesProvider.addItem(routineId, item);
  }

  // Edit item
  Future<void> editItem(
    String itemId, {
    String? title,
    int? iconCodePoint,
  }) async {
    await _routinesProvider.editItem(
      routineId,
      itemId,
      title: title,
      iconCodePoint: iconCodePoint,
    );
  }

  // Delete item
  Future<void> deleteItem(String itemId) async {
    await _routinesProvider.deleteItem(routineId, itemId);
  }

  // Delete routine
  Future<void> deleteRoutine() async {
    await _routinesProvider.deleteRoutine(routineId);
  }

  // Reorder items
  Future<void> reorderItems(int oldIndex, int newIndex) async {
    await _routinesProvider.reorderItems(routineId, oldIndex, newIndex);
  }


}

