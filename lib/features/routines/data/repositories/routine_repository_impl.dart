import '../../domain/entities/routine.dart';
import '../../domain/repositories/routine_repository.dart';
import '../datasources/routine_local_datasource.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  final RoutineLocalDataSource local;

  RoutineRepositoryImpl({required this.local});

  @override
  Future<List<Routine>> getRoutines() => local.getRoutines();

  @override
  Future<Routine> addRoutine(Routine routine) => local.addRoutine(routine);

  @override
  Future<Routine> updateRoutine(Routine routine) =>
      local.updateRoutine(routine);

  @override
  Future<void> deleteRoutine(String id) => local.deleteRoutine(id);
}
