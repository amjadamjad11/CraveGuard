import '../services/api_service.dart';
import '../services/demo_service.dart';

/// Repository that abstracts risk-zone / location data access.
/// Returns demo data when [isDemoMode] is true, otherwise calls the real API.
class LocationRepository {
  final ApiService api;
  final DemoService demo;
  final bool isDemoMode;

  LocationRepository({
    required this.api,
    required this.demo,
    required this.isDemoMode,
  });

  /// Returns all risk zones (user-defined and AI-detected).
  Future<List<Map<String, dynamic>>> getRiskZones() async {
    if (isDemoMode) {
      return demo.riskZones;
    }
    final resp = await api.get('/location/risk-zones');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  /// Adds a new risk zone.
  Future<void> addRiskZone(Map<String, dynamic> zone) async {
    if (isDemoMode) {
      return;
    }
    await api.post('/location/risk-zones', data: zone);
  }

  /// Deletes an existing risk zone by [id].
  Future<void> deleteRiskZone(int id) async {
    if (isDemoMode) {
      return;
    }
    await api.delete('/location/risk-zones/$id');
  }
}
