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
    try {
      final resp = await api.get('/location/risk-zones');
      final list = List<Map<String, dynamic>>.from(resp.data);
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return demo.riskZones;
  }

  /// Adds a new risk zone.
  Future<void> addRiskZone(Map<String, dynamic> zone) async {
    if (isDemoMode) {
      demo.riskZones.add(zone);
      return;
    }
    await api.post('/location/risk-zones', data: zone);
  }

  /// Updates an existing risk zone.
  Future<void> updateRiskZone(int id, Map<String, dynamic> zone) async {
    if (isDemoMode) {
      final index = demo.riskZones.indexWhere((z) => z['id'] == id);
      if (index != -1) {
        demo.riskZones[index] = {...demo.riskZones[index], ...zone};
      }
      return;
    }
    await api.put('/location/risk-zones/$id', data: zone);
  }

  /// Confirms a suggested risk zone.
  Future<void> confirmRiskZone(int id) async {
    if (isDemoMode) {
      final index = demo.riskZones.indexWhere((z) => z['id'] == id);
      if (index != -1) {
        demo.riskZones[index]['is_user_confirmed'] = true;
      }
      return;
    }
    await api.post('/location/risk-zones/$id/confirm');
  }

  /// Deletes an existing risk zone by [id].
  Future<void> deleteRiskZone(int id) async {
    if (isDemoMode) {
      demo.riskZones.removeWhere((z) => z['id'] == id);
      return;
    }
    await api.delete('/location/risk-zones/$id');
  }

  /// Obtains auto-detected candidate risk locations.
  Future<List<Map<String, dynamic>>> getRiskCandidates() async {
    if (isDemoMode) {
      return [
        {
          'name': 'Corner Store / Chai Point',
          'latitude': 28.6220,
          'longitude': 77.2180,
          'smoking_events_nearby': 4,
          'craving_events_nearby': 2,
          'risk_level': 'medium',
          'risk_score': 0.65,
          'factors': [
            'You recorded smoking near here 4 times and cravings 2 times.',
            'Common times: 4:00 PM - 5:30 PM (Tea break trigger)',
          ],
        }
      ];
    }
    final resp = await api.get('/location/risk-candidates');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  /// Records an entry or exit geofence event.
  Future<void> recordGeofenceEvent(Map<String, dynamic> event) async {
    if (isDemoMode) {
      return;
    }
    await api.post('/location/geofence-events', data: event);
  }
}
