import '../entities/recording.dart';
import '../repositories/affirmation_repository.dart';
import '../../../../core/utils/result.dart';

/// Use case for saving a session log entry
class SaveAffirmationSession {
  final AffirmationRepository repository;

  SaveAffirmationSession(this.repository);

  Future<Result<void>> call(SessionLog log) async {
    return await repository.logSession(log);
  }
}
