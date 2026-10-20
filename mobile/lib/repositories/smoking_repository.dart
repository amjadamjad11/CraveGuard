import '../services/api_service.dart';
import '../services/demo_service.dart';

/// Repository that abstracts smoking data access.
/// Returns demo data when [isDemoMode] is true, otherwise calls the real API.
class SmokingRepository {
  final ApiService api;
  final DemoService demo;
  final bool isDemoMode;

  SmokingRepository({
    required this.api,
    required this.demo,
    required this.isDemoMode,
  });

  /// Returns the number of cigarettes smoked today.
  Future<int> getTodayCount() async {
    if (isDemoMode) {
      return demo.todaySmokingCount;
    }
    final resp = await api.get('/smoking/today-count');
    return resp.data['count'] as int;
  }

  /// Returns daily smoking counts for the past 7 days.
  Future<List<Map<String, dynamic>>> getWeeklyData() async {
    if (isDemoMode) {
      return demo.weeklySmokingData;
    }
    final resp = await api.get('/smoking/weekly-data');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  /// Returns all smoking events (past 14 days in demo mode).
  Future<List<Map<String, dynamic>>> getSmokingEvents() async {
    if (isDemoMode) {
      return demo.smokingEvents;
    }
    final resp = await api.get('/smoking/smoking-events');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  /// Returns the top trigger categories ranked by frequency.
  Future<List<Map<String, dynamic>>> getTopTriggers() async {
    if (isDemoMode) {
      return demo.topTriggers;
    }
    final resp = await api.get('/smoking/top-triggers');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  /// Logs a new smoking event.
  Future<void> logSmokingEvent(Map<String, dynamic> event) async {
    if (isDemoMode) {
      // No-op in demo mode – the UI can optimistically add the event locally.
      return;
    }
    await api.post('/smoking/smoking-events', data: event);
  }

  /// Returns all craving events.
  Future<List<Map<String, dynamic>>> getCravingEvents() async {
    if (isDemoMode) {
      return demo.cravingEvents;
    }
    final resp = await api.get('/smoking/craving-events');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  /// Logs a new craving event.
  Future<void> logCravingEvent(Map<String, dynamic> event) async {
    if (isDemoMode) {
      return;
    }
    await api.post('/smoking/craving-events', data: event);
  }
}
