import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/app_providers.dart';
import '../../../theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Navigate after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), _navigate);
  }

  Future<void> _navigate() async {
    if (_navigated || !mounted) return;

    // Wait until auth state resolves out of loading (max 5s).
    // Guard every check with mounted so we don't use ref after disposal.
    int waited = 0;
    while (mounted &&
        ref.read(authStateProvider) == AuthState.loading &&
        waited < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited++;
    }

    // Widget may have been disposed during the await — bail out safely.
    if (!mounted) return;
    _navigated = true;

    final authState = ref.read(authStateProvider);
    final onboardingInProgress = ref.read(onboardingInProgressProvider);

    if (authState == AuthState.authenticated) {
      context.go('/home');
    } else if (onboardingInProgress) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.darkNavy,
              AppColors.deepNavy,
              AppColors.deepTeal,
            ],
            stops: [0.0, 0.55, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // Logo + App Name
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Shield icon with heart
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.teal, AppColors.mintGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.shield,
                              size: 64,
                              color: AppColors.darkNavy,
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.favorite,
                                size: 28,
                                color: AppColors.warmWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // App name
                      Text(
                        'CraveGuard',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warmWhite,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: AppColors.teal.withValues(alpha: 0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Tagline
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Your journey to freedom,\none breath at a time',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondaryDark,
                        height: 1.6,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Subtle loading dots
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                ),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.teal.withValues(alpha: 0.6),
                  ),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
