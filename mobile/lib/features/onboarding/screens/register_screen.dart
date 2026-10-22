import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePass = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

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
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.mintGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )],
                    ),
                    child: const Icon(Icons.shield_rounded, size: 44, color: Colors.white),
                  ).animate().fadeIn(duration: 500.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    curve: Curves.elasticOut,
                  ),
                  const SizedBox(height: 20),
                  Text('Create Account',
                    style: Theme.of(context).textTheme.headlineLarge)
                    .animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 6),
                  Text('Join CraveGuard — your journey starts here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryDark),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 32),

                  // Name field
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Preferred name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05, end: 0),
                  const SizedBox(height: 14),

                  // Email field
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ).animate().fadeIn(delay: 380.ms).slideX(begin: -0.05, end: 0),
                  const SizedBox(height: 14),

                  // Password field
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      hintText: 'Password (min 6 characters)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                  ).animate().fadeIn(delay: 460.ms).slideX(begin: -0.05, end: 0),
                  const SizedBox(height: 14),

                  // Confirm password
                  TextField(
                    controller: _confirmPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ).animate().fadeIn(delay: 540.ms).slideX(begin: -0.05, end: 0),

                  // Error message
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create Account'),
                    ),
                  ).animate().fadeIn(delay: 620.ms),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Sign In'),
                  ).animate().fadeIn(delay: 700.ms),

                  const SizedBox(height: 24),
                  // Info note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: AppColors.teal, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'After creating your account you will complete a short onboarding survey, '
                          'then sign in to start using CraveGuard.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.teal, height: 1.5),
                        ),
                      ),
                    ]),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    // register() stores a temp token but does NOT set AuthState.authenticated
    final token = await ref.read(authStateProvider.notifier)
        .register(email, pass, name);

    setState(() => _loading = false);

    if (token != null && mounted) {
      // Navigate to onboarding to complete the survey
      context.go('/onboarding');
    } else if (mounted) {
      setState(() => _error = 'Registration failed. This email may already be registered.');
    }
  }
}
