import '../entities/recording.dart';
import '../repositories/affirmation_repository.dart';
import '../../../../core/utils/result.dart';

/// Use case for saving a new recording
class SaveRecording {
  final AffirmationRepository repository;

  SaveRecording(this.repository);

  Future<Result<void>> call(SavedRecording recording) async {
    return await repository.saveRecording(recording);
  }
}
