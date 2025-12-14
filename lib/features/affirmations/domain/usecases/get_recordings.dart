import '../entities/recording.dart';
import '../repositories/affirmation_repository.dart';
import '../../../../core/utils/result.dart';

/// Use case for getting all saved recordings
class GetRecordings {
  final AffirmationRepository repository;

  GetRecordings(this.repository);

  Future<Result<List<SavedRecording>>> call() async {
    return await repository.getRecordings();
  }
}
