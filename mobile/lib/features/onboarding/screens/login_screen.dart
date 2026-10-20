import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _aboutExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Branded logo with gradient
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: AppColors.mintGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_rounded, size: 52, color: Colors.white),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 20),
                  Text('CraveGuard', style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.mintGreen, fontWeight: FontWeight.w700, letterSpacing: -0.5))
                      .animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 6),
                  Text('Your journey to freedom starts here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark))
                      .animate().fadeIn(delay: 400.ms, duration: 500.ms),
                  const SizedBox(height: 40),

                  // Email field
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(begin: -0.05, end: 0),
                  const SizedBox(height: 16),

                  // Password field
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideX(begin: -0.05, end: 0),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Sign In button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In'),
                    ),
                  ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text("Don't have an account? Sign Up"),
                  ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
                  const SizedBox(height: 28),
                  const Divider(color: AppColors.navyLight),
                  const SizedBox(height: 16),

                  // Demo mode button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _enterDemo,
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Try Demo Mode'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.mintGreen),
                        foregroundColor: AppColors.mintGreen,
                      ),
                    ),
                  ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
                  const SizedBox(height: 8),
                  Text('Explore all features with sample data',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiaryDark)),

                  // "What is CraveGuard?" expandable section
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => setState(() => _aboutExpanded = !_aboutExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.navyLight),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.help_outline, color: AppColors.teal, size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text('What is CraveGuard?',
                                  style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w500, fontSize: 14)),
                              ),
                              AnimatedRotation(
                                turns: _aboutExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondaryDark),
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                'CraveGuard is an AI-powered smoking cessation companion that helps you understand your habits, '
                                'manage cravings in real-time, and track your progress toward a smoke-free life. '
                                'It uses personalized insights, risk zone mapping, and motivational support to keep you on track.\n\n'
                                '• Track smoking patterns & triggers\n'
                                '• AI coach for real-time craving support\n'
                                '• Geofenced risk zone alerts\n'
                                '• Financial savings tracker\n'
                                '• Personal motivation vault',
                                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, height: 1.6),
                              ),
                            ),
                            crossFadeState: _aboutExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final success = await ref.read(authStateProvider.notifier).login(_emailCtrl.text, _passCtrl.text);
    setState(() => _loading = false);
    if (!success && mounted) setState(() => _error = 'Invalid credentials. Try demo mode or register.');
  }

  Future<void> _enterDemo() async {
    await ref.read(authStateProvider.notifier).enterDemoMode();
    if (mounted) context.go('/home');
  }
}
