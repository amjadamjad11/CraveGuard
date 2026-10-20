import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../features/onboarding/screens/splash_screen.dart';
import '../features/onboarding/screens/login_screen.dart';
import '../features/onboarding/screens/register_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/smoking_tracker/screens/smoking_log_screen.dart';
import '../features/risk_map/screens/risk_map_screen.dart';
import '../features/ai_chat/screens/chat_screen.dart';
import '../features/progress/screens/progress_screen.dart';
import '../features/savings/screens/savings_screen.dart';
import '../features/motivation_vault/screens/motivation_vault_screen.dart';
import '../features/trusted_support/screens/trusted_contacts_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/about_screen.dart';
import '../features/craving_support/screens/craving_flow_screen.dart';
import '../app/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (state.matchedLocation == '/splash') return null;
      if (authState == AuthState.loading) return null;
      final isAuth = authState == AuthState.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/patterns', builder: (context, state) => const SmokingLogScreen()),
          GoRoute(path: '/risk-map', builder: (context, state) => const RiskMapScreen()),
          GoRoute(path: '/coach', builder: (context, state) => const ChatScreen()),
          GoRoute(path: '/progress', builder: (context, state) => const ProgressScreen()),
        ],
      ),
      GoRoute(path: '/savings', builder: (context, state) => const SavingsScreen()),
      GoRoute(path: '/motivation-vault', builder: (context, state) => const MotivationVaultScreen()),
      GoRoute(path: '/trusted-contacts', builder: (context, state) => const TrustedContactsScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(path: '/craving-support', builder: (context, state) => const CravingFlowScreen()),
    ],
  );
});
