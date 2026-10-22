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
final demoModeProvider = StateProvider<bool>((ref) => false);

// --- Theme ---
final isDarkModeProvider = StateProvider<bool>((ref) => true);

// --- Auth state ---
enum AuthState { loading, authenticated, unauthenticated }

// ---------------------------------------------------------------------------
// Onboarding state — separate from auth so registration doesn't falsely
// authenticate the user into the app.
// ---------------------------------------------------------------------------

/// True while the user has a *temporary registration token* and is completing
/// the onboarding survey.  This is NOT the same as being logged into the app.
final onboardingInProgressProvider = StateProvider<bool>((ref) => false);

/// The user's preferred name shown on the onboarding screen.
final pendingPreferredNameProvider = StateProvider<String>((ref) => 'Friend');

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  String? userName;

  AuthNotifier(this._ref) : super(AuthState.loading) {
    _checkAuth();
  }

  /// On startup, check the stored token and onboarding status.
  Future<void> _checkAuth() async {
    try {
      final api = _ref.read(apiServiceProvider);
      final token = await api.getToken();

      // Check if we are in demo mode
      final isDemo = await _ref.read(storageServiceProvider).isDemoMode;
      if (isDemo) {
        _ref.read(demoModeProvider.notifier).state = true;
        _ref.read(apiServiceProvider).isDemoMode = true;
        userName = 'Demo User';
        state = AuthState.authenticated;
        return;
      }

      if (token == null) {
        state = AuthState.unauthenticated;
        return;
      }

      // Token exists — verify it and get onboarding status
      try {
        final resp = await api.get('/auth/me');
        if (resp.statusCode == 200) {
          final data = resp.data as Map<String, dynamic>;
          userName = data['preferred_name'] ?? 'Friend';
          final onboardingComplete = data['onboarding_complete'] as bool? ?? false;

          if (!onboardingComplete) {
            // Token is valid but onboarding is not done.
            // Mark as onboarding-in-progress (not authenticated into main app).
            _ref.read(onboardingInProgressProvider.notifier).state = true;
            _ref.read(pendingPreferredNameProvider.notifier).state =
                data['preferred_name'] ?? 'Friend';
            state = AuthState.unauthenticated;
          } else {
            state = AuthState.authenticated;
          }
        } else {
          await api.clearToken();
          state = AuthState.unauthenticated;
        }
      } catch (_) {
        // Token is expired / invalid
        await api.clearToken();
        state = AuthState.unauthenticated;
      }
    } catch (_) {
      state = AuthState.unauthenticated;
    }
  }

  // -------------------------------------------------------------------------
  // Login — sends x-www-form-urlencoded as required by OAuth2PasswordRequestForm
  // -------------------------------------------------------------------------
  Future<bool> login(String email, String password) async {
    try {
      final api = _ref.read(apiServiceProvider);
      // OAuth2PasswordRequestForm requires form encoding, NOT JSON
      final resp = await api.postForm(
        '/auth/login',
        {'username': email.trim().toLowerCase(), 'password': password},
      );
      if (resp.statusCode == 200) {
        final token = resp.data['access_token'] as String;
        await api.setToken(token);

        // Fetch /me to get onboarding status and name
        final meResp = await api.get('/auth/me');
        if (meResp.statusCode == 200) {
          final data = meResp.data as Map<String, dynamic>;
          userName = data['preferred_name'] ?? 'Friend';
          final onboardingComplete =
              data['onboarding_complete'] as bool? ?? false;
          if (!onboardingComplete) {
            // Still needs onboarding — keep token so onboarding can save
            _ref.read(onboardingInProgressProvider.notifier).state = true;
            _ref.read(pendingPreferredNameProvider.notifier).state =
                data['preferred_name'] ?? 'Friend';
            // We return true so the caller knows the credentials are valid;
            // the router will redirect to /onboarding.
          }
          state = AuthState.authenticated;
        } else {
          state = AuthState.authenticated;
        }
        return true;
      }
    } catch (e) {
      // DioException with 401 → invalid credentials
    }
    return false;
  }

  // -------------------------------------------------------------------------
  // Register — does NOT authenticate into the main app.
  // Returns the temporary token so the caller can use it during onboarding.
  // -------------------------------------------------------------------------
  Future<String?> register(
      String email, String password, String name) async {
    try {
      final api = _ref.read(apiServiceProvider);
      final resp = await api.post('/auth/register', data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'preferred_name': name.trim().isEmpty ? 'Friend' : name.trim(),
        'age_confirmed': true,
      });
      if (resp.statusCode == 200) {
        final token = resp.data['access_token'] as String;
        // Store token TEMPORARILY so onboarding can call the API
        await api.setToken(token);
        _ref.read(pendingPreferredNameProvider.notifier).state =
            resp.data['preferred_name'] ?? name;
        _ref.read(onboardingInProgressProvider.notifier).state = true;
        // Do NOT set AuthState.authenticated — user is not in the app yet
        return token;
      }
    } catch (e) {
      // Registration error
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Complete onboarding — saves answers to backend, clears temp token, goes
  // to login.
  // -------------------------------------------------------------------------
  Future<bool> completeOnboarding(Map<String, dynamic> payload) async {
    try {
      final api = _ref.read(apiServiceProvider);
      final resp =
          await api.post('/profile/complete-onboarding', data: payload);
      if (resp.statusCode == 200) {
        // Onboarding done — clear the temporary registration token and reset state.
        await api.clearToken();
        _ref.read(onboardingInProgressProvider.notifier).state = false;
        // State stays unauthenticated → router will go to /login
        return true;
      }
    } catch (_) {}
    return false;
  }

  // -------------------------------------------------------------------------
  // Demo mode
  // -------------------------------------------------------------------------
  Future<void> enterDemoMode() async {
    _ref.read(demoModeProvider.notifier).state = true;
    _ref.read(apiServiceProvider).isDemoMode = true;
    await _ref.read(storageServiceProvider).setDemoMode(true);
    userName = 'Demo User';
    state = AuthState.authenticated;
  }

  // -------------------------------------------------------------------------
  // Logout
  // -------------------------------------------------------------------------
  Future<void> logout() async {
    await _ref.read(apiServiceProvider).clearToken();
    await _ref.read(storageServiceProvider).setDemoMode(false);
    _ref.read(demoModeProvider.notifier).state = false;
    _ref.read(apiServiceProvider).isDemoMode = false;
    _ref.read(onboardingInProgressProvider.notifier).state = false;
    userName = null;
    state = AuthState.unauthenticated;
  }
}

// --- Onboarding ---
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

// --- Smoking Data ---
final todaySmokingCountProvider = StateProvider<int>((ref) => 0);
final weeklySmokingDataProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);
final smokingEventsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);
final topTriggersProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Craving ---
final cravingEventsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Savings ---
final savingsDataProvider =
    StateProvider<Map<String, dynamic>>((ref) => {});
final savingsGoalsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Risk Zones ---
final riskZonesProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);
final suggestedRiskZonesProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Chat ---
final chatMessagesProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);
final chatConversationIdProvider = StateProvider<int?>((ref) => null);

// --- Milestones ---
final milestonesProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Progress ---
final dailySummaryProvider =
    StateProvider<Map<String, dynamic>>((ref) => {});

// --- Interventions ---
final recommendedInterventionProvider =
    StateProvider<Map<String, dynamic>>((ref) => {});

// --- Motivation ---
final motivationalMediaProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Trusted Contacts ---
final trustedContactsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// --- Profile ---
final userProfileProvider =
    StateProvider<Map<String, dynamic>>((ref) => {});

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
  return ref
      .watch(chatRepoProvider)
      .getMessages(conversationId: conversationId);
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
