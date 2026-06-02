import '../../data/services/analysis_service.dart';

/// Returns the weekly insight string for the push notification, or null when
/// there is insufficient data or the correlation is too weak to surface.
///
/// Covers water/mood correlation only (v1). Future versions can extend this
/// to cycle across all three AnalysisService insight types.
class ComputeWeeklyInsight {
  Future<String?> call() => AnalysisService().analyzeWaterMoodCorrelation();
}
