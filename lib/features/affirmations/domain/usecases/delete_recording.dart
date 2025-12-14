import '../repositories/affirmation_repository.dart';
import '../../../../core/utils/result.dart';

/// Use case for deleting a recording
class DeleteRecording {
  final AffirmationRepository repository;

  DeleteRecording(this.repository);

  Future<Result<void>> call(String id) async {
    return await repository.deleteRecording(id);
  }
}
