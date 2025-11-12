import 'package:flutter/foundation.dart';
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
    debugPrint('Hive updateRoutine: Updating routine ${routine.id} with ${routine.items.length} items');
    await _box!.put(routine.id, routine);
    debugPrint('Hive updateRoutine: Successfully updated routine ${routine.id}');
    
    // Verify the update
    final saved = _box!.get(routine.id);
    debugPrint('Hive updateRoutine: Verified - saved routine has ${saved?.items.length ?? 0} items');
    
    return routine;
  }

  @override
  Future<void> deleteRoutine(String id) async {
    await _box!.delete(id);
  }
}
