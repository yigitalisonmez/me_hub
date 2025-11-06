import '../entities/routine.dart';

abstract class RoutineRepository {
  Future<List<Routine>> getRoutines();
  Future<Routine> addRoutine(Routine routine);
  Future<Routine> updateRoutine(Routine routine);
  Future<void> deleteRoutine(String id);
}


