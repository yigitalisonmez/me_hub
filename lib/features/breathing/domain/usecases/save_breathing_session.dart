import '../entities/breathing_session.dart';
import '../repositories/breathing_repository.dart';
import '../../../../core/utils/result.dart';

/// Use case for saving a breathing session
class SaveBreathingSession {
  final BreathingRepository repository;

  SaveBreathingSession(this.repository);

  Future<Result<void>> call(BreathingSession session) async {
    return await repository.saveSession(session);
  }
}
