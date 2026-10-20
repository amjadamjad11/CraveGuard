import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/demo_service.dart';
import '../services/storage_service.dart';
import '../repositories/smoking_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/location_repository.dart';
import '../repositories/motivation_repository.dart';
import '../repositories/intervention_repository.dart';

// --- Core service providers ---
final apiServiceProvider = Provider((ref) => ApiService());
final demoServiceProvider = Provider((ref) => DemoService());
final storageServiceProvider = Provider((ref) => StorageService());

// --- Demo mode ---
final demoModeProvider = StateProvider<bool>((ref) => true);

// --- Theme ---
final isDarkModeProvider = StateProvider<bool>((ref) => true);

// --- Auth state ---
enum AuthState { loading, authenticated, unauthenticated }

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  String? userName;

  AuthNotifier(this._ref) : super(AuthState.loading) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _ref.read(apiServiceProvider).getToken();
    final isDemo = await _ref.read(storageServiceProvider).isDemoMode;
    if (isDemo) {
      _ref.read(demoModeProvider.notifier).state = true;
      userName = 'Demo User';
      state = AuthState.authenticated;
    } else if (token != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final api = _ref.read(apiServiceProvider);
      final resp = await api.post('/auth/login',
          data: 'username=$email&password=$password');
      if (resp.statusCode == 200) {
        await api.setToken(resp.data['access_token']);
        state = AuthState.authenticated;
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      final api = _ref.read(apiServiceProvider);
      final resp = await api.post('/auth/register', data: {
        'email': email,
        'password': password,
        'preferred_name': name,
        'age_confirmed': true,
      });
      if (resp.statusCode == 200) {
        await api.setToken(resp.data['access_token']);
        userName = name;
        state = AuthState.authenticated;
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> enterDemoMode() async {
    _ref.read(demoModeProvider.notifier).state = true;
    _ref.read(apiServiceProvider).isDemoMode = true;
    await _ref.read(storageServiceProvider).setDemoMode(true);
    userName = 'Demo User';
    state = AuthState.authenticated;
  }

  Future<void> logout() async {
    await _ref.read(apiServiceProvider).clearToken();
    await _ref.read(storageServiceProvider).setDemoMode(false);
    _ref.read(demoModeProvider.notifier).state = false;
    _ref.read(apiServiceProvider).isDemoMode = false;
    state = AuthState.unauthenticated;
  }
}

// --- Onboarding ---
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

// --- Smoking Data ---
final todaySmokingCountProvider = StateProvider<int>((ref) => 0);

final weeklySmokingDataProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

final smokingEventsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

final topTriggersProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Craving ---
final cravingEventsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Savings ---
final savingsDataProvider = StateProvider<Map<String, dynamic>>((ref) => {});

final savingsGoalsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Risk Zones ---
final riskZonesProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Chat ---
final chatMessagesProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

final chatConversationIdProvider = StateProvider<int?>((ref) => null);

// --- Milestones ---
final milestonesProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Progress ---
final dailySummaryProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// --- Interventions ---
final recommendedInterventionProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// --- Motivation ---
final motivationalMediaProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Trusted Contacts ---
final trustedContactsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Profile ---
final userProfileProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// ===========================================================================
// Repository providers — seamless demo / API switching
// ===========================================================================

final smokingRepoProvider = Provider<SmokingRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  final demo = ref.read(demoServiceProvider);
  final isDemo = ref.read(demoModeProvider);
  return SmokingRepository(api: api, demo: demo, isDemoMode: isDemo);
});

final progressRepoProvider = Provider<ProgressRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  final demo = ref.read(demoServiceProvider);
  final isDemo = ref.read(demoModeProvider);
  return ProgressRepository(api: api, demo: demo, isDemoMode: isDemo);
});

final chatRepoProvider = Provider<ChatRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  final demo = ref.read(demoServiceProvider);
  final isDemo = ref.read(demoModeProvider);
  return ChatRepository(api: api, demo: demo, isDemoMode: isDemo);
});

final locationRepoProvider = Provider<LocationRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  final demo = ref.read(demoServiceProvider);
  final isDemo = ref.read(demoModeProvider);
  return LocationRepository(api: api, demo: demo, isDemoMode: isDemo);
});

final motivationRepoProvider = Provider<MotivationRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  final demo = ref.read(demoServiceProvider);
  final isDemo = ref.read(demoModeProvider);
  return MotivationRepository(api: api, demo: demo, isDemoMode: isDemo);
});

final interventionRepoProvider = Provider<InterventionRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  final demo = ref.read(demoServiceProvider);
  final isDemo = ref.read(demoModeProvider);
  return InterventionRepository(api: api, demo: demo, isDemoMode: isDemo);
});

// ===========================================================================
// FutureProviders — initial data loading via repositories
// ===========================================================================

final todayCountFutureProvider = FutureProvider<int>((ref) {
  return ref.watch(smokingRepoProvider).getTodayCount();
});

final weeklyDataFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(smokingRepoProvider).getWeeklyData();
});

final smokingEventsFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(smokingRepoProvider).getSmokingEvents();
});

final topTriggersFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(smokingRepoProvider).getTopTriggers();
});

final cravingEventsFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(smokingRepoProvider).getCravingEvents();
});

final dailySummaryFutureProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(progressRepoProvider).getDailySummary();
});

final savingsDataFutureProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(progressRepoProvider).getSavingsData();
});

final milestonesFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(progressRepoProvider).getMilestones();
});

final savingsGoalsFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(progressRepoProvider).getSavingsGoals();
});

final chatMessagesFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final conversationId = ref.watch(chatConversationIdProvider);
  return ref.watch(chatRepoProvider).getMessages(conversationId: conversationId);
});

final riskZonesFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(locationRepoProvider).getRiskZones();
});

final motivationalMediaFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(motivationRepoProvider).getMotivationalMedia();
});

final trustedContactsFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(motivationRepoProvider).getTrustedContacts();
});

final recommendedInterventionFutureProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(interventionRepoProvider).getRecommendation();
});
