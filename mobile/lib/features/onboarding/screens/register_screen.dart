import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _loading = false;
  String? _error;

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
                  const Icon(Icons.shield_rounded, size: 48, color: AppColors.mintGreen),
                  const SizedBox(height: 16),
                  Text('Create Account', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text('Join CraveGuard and start your journey',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark)),
                  const SizedBox(height: 40),
                  TextField(controller: _nameCtrl,
                    decoration: const InputDecoration(hintText: 'Preferred name', prefixIcon: Icon(Icons.person_outline))),
                  const SizedBox(height: 16),
                  TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 16),
                  TextField(controller: _passCtrl, obscureText: true,
                    decoration: const InputDecoration(hintText: 'Password (min 6 chars)', prefixIcon: Icon(Icons.lock_outline))),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.length < 6) {
      setState(() => _error = 'Please fill all fields (password min 6 characters)');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final success = await ref.read(authStateProvider.notifier).register(
      _emailCtrl.text, _passCtrl.text, _nameCtrl.text);
    setState(() => _loading = false);
    if (success && mounted) {
      context.go('/onboarding');
    } else if (mounted) {
      setState(() => _error = 'Registration failed. Email may already exist.');
    }
  }
}
