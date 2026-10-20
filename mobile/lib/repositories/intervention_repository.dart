import '../services/api_service.dart';
import '../services/demo_service.dart';

/// Repository that abstracts intervention recommendation data access.
/// Returns demo data when [isDemoMode] is true, otherwise calls the real API.
class InterventionRepository {
  final ApiService api;
  final DemoService demo;
  final bool isDemoMode;

  InterventionRepository({
    required this.api,
    required this.demo,
    required this.isDemoMode,
  });

  /// Returns a recommended intervention based on optional [trigger] and [intensity].
  Future<Map<String, dynamic>> getRecommendation({
    String? trigger,
    int? intensity,
  }) async {
    if (isDemoMode) {
      return demo.recommendedIntervention;
    }
    final queryParams = <String, dynamic>{};
    if (trigger != null) queryParams['trigger'] = trigger;
    if (intensity != null) queryParams['intensity'] = intensity;
    final resp =
        await api.get('/interventions/recommend', queryParams: queryParams);
    return Map<String, dynamic>.from(resp.data);
  }

  /// Submits feedback on whether an intervention was helpful.
  Future<void> submitFeedback(int interventionId, bool helpful) async {
    if (isDemoMode) {
      return;
    }
    await api.post('/interventions/feedback', data: {
      'intervention_id': interventionId,
      'helpful': helpful,
    });
  }
}
