import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/routine.dart';

abstract class RoutineLocalDataSource {
  Future<void> init();
  Future<List<Routine>> getRoutines();
  Future<Routine> addRoutine(Routine routine);
  Future<Routine> updateRoutine(Routine routine);
  Future<void> deleteRoutine(String id);
}

class RoutineLocalDataSourceImpl implements RoutineLocalDataSource {
  static const String _boxName = 'routines_box';
  Box<Routine>? _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox<Routine>(_boxName);
  }

  @override
  Future<List<Routine>> getRoutines() async {
    return _box!.values.toList();
  }

  @override
  Future<Routine> addRoutine(Routine routine) async {
    await _box!.put(routine.id, routine);
    return routine;
  }

  @override
  Future<Routine> updateRoutine(Routine routine) async {
    await _box!.put(routine.id, routine);
    return routine;
  }

  @override
  Future<void> deleteRoutine(String id) async {
    await _box!.delete(id);
  }
}
