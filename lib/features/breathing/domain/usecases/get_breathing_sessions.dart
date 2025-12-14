import '../entities/breathing_session.dart';
import '../repositories/breathing_repository.dart';
import '../../../../core/utils/result.dart';

/// Use case for getting all breathing sessions
class GetBreathingSessions {
  final BreathingRepository repository;

  GetBreathingSessions(this.repository);

  Future<Result<List<BreathingSession>>> call() async {
    return await repository.getSessions();
  }
}
