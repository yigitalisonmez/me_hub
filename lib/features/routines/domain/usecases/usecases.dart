import '../entities/routine.dart';
import '../repositories/routine_repository.dart';

class GetRoutines {
  final RoutineRepository repo;
  GetRoutines(this.repo);
  Future<List<Routine>> call() => repo.getRoutines();
}

class AddRoutine {
  final RoutineRepository repo;
  AddRoutine(this.repo);
  Future<Routine> call(Routine routine) => repo.addRoutine(routine);
}

class UpdateRoutine {
  final RoutineRepository repo;
  UpdateRoutine(this.repo);
  Future<Routine> call(Routine routine) => repo.updateRoutine(routine);
}

class DeleteRoutine {
  final RoutineRepository repo;
  DeleteRoutine(this.repo);
  Future<void> call(String id) => repo.deleteRoutine(id);
}


