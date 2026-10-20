import '../services/api_service.dart';
import '../services/demo_service.dart';

/// Repository that abstracts progress / savings data access.
/// Returns demo data when [isDemoMode] is true, otherwise calls the real API.
class ProgressRepository {
  final ApiService api;
  final DemoService demo;
  final bool isDemoMode;

  ProgressRepository({
    required this.api,
    required this.demo,
    required this.isDemoMode,
  });

  /// Returns today's daily summary (cigarettes smoked, cravings, etc.).
  Future<Map<String, dynamic>> getDailySummary() async {
    if (isDemoMode) {
      return demo.dailySummary;
    }
    final resp = await api.get('/progress/daily-summary');
    return Map<String, dynamic>.from(resp.data);
  }

  /// Returns accumulated savings data.
  Future<Map<String, dynamic>> getSavingsData() async {
    if (isDemoMode) {
      return demo.savingsData;
    }
    final resp = await api.get('/progress/savings');
    return Map<String, dynamic>.from(resp.data);
  }

  /// Returns a list of milestones with achievement status.
  Future<List<Map<String, dynamic>>> getMilestones() async {
    if (isDemoMode) {
      return demo.milestones;
    }
    final resp = await api.get('/progress/milestones');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  /// Returns the user's savings goals.
  Future<List<Map<String, dynamic>>> getSavingsGoals() async {
    if (isDemoMode) {
      return demo.savingsGoals;
    }
    final resp = await api.get('/progress/savings-goals');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  /// Creates a new savings goal.
  Future<void> createSavingsGoal(Map<String, dynamic> goal) async {
    if (isDemoMode) {
      return;
    }
    await api.post('/progress/savings-goals', data: goal);
  }
}
