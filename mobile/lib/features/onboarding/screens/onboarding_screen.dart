import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../core/constants.dart';
import '../../../providers/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  bool _saving = false;
  String? _saveError;

  // Step 1: Profile
  final _nameCtrl = TextEditingController();
  String _language = 'English';

  // Step 2: Habits
  final _cigsPerDayCtrl = TextEditingController(text: '10');
  final _packPriceCtrl = TextEditingController(text: '250');
  final _cigsPerPackCtrl = TextEditingController(text: '20');
  String _firstSmokeAfterWaking = 'Within 30 minutes';
  String _currentGoal = 'Gradually reduce';

  // Step 3: Triggers
  final Set<String> _selectedTriggers = {};

  // Step 4: Quit reasons
  final Set<String> _selectedReasons = {};
  final _personalReasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill name from registration
    _nameCtrl.text = ref.read(pendingPreferredNameProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameCtrl.dispose();
    _cigsPerDayCtrl.dispose();
    _packPriceCtrl.dispose();
    _cigsPerPackCtrl.dispose();
    _personalReasonCtrl.dispose();
    super.dispose();
  }

  static const int _totalPages = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with progress indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0
                          ? () => _controller.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut)
                          : null,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: _currentPage > 0
                            ? AppColors.textPrimaryDark
                            : Colors.transparent,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: List.generate(_totalPages, (i) => Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: i <= _currentPage
                                  ? AppColors.teal
                                  : AppColors.navyLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${_currentPage + 1}/$_totalPages',
                      style: TextStyle(
                        color: AppColors.textSecondaryDark, fontSize: 12)),
                  ],
                ),
              ),
              // Pages
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _profileStep(),
                    _habitsStep(),
                    _triggersStep(),
                    _reasonsStep(),
                    _reviewStep(),
                  ],
                ),
              ),
              // Navigation buttons
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_saveError!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12))),
                    ]),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _handleNext,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_currentPage < _totalPages - 1
                            ? 'Continue'
                            : 'Complete & Go to Login'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNext() {
    if (_currentPage < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  // -------------------------------------------------------------------------
  // Steps
  // -------------------------------------------------------------------------

  Widget _profileStep() => _stepContainer(
    icon: Icons.person_outline,
    title: 'Welcome to CraveGuard',
    subtitle: 'Let\'s get to know you a little.',
    children: [
      TextField(
        controller: _nameCtrl,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'What should we call you?',
          prefixIcon: Icon(Icons.badge_outlined)),
      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05, end: 0),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _language,
        dropdownColor: AppColors.cardDark,
        decoration: const InputDecoration(
          labelText: 'Language',
          prefixIcon: Icon(Icons.language)),
        items: ['English', 'Hindi', 'Tamil', 'Telugu']
            .map((l) => DropdownMenuItem(value: l, child: Text(l)))
            .toList(),
        onChanged: (v) => setState(() => _language = v!),
      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05, end: 0),
      const SizedBox(height: 20),
      _infoBox('Your information stays private and is only used to personalize your experience.'),
    ],
  );

  Widget _habitsStep() => _stepContainer(
    icon: Icons.smoking_rooms,
    title: 'Your Smoking Habits',
    subtitle: 'This sets your personal baseline. You can update anytime.',
    children: [
      TextField(
        controller: _cigsPerDayCtrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Cigarettes per day',
          prefixIcon: Icon(Icons.filter_1)),
      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05, end: 0),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _packPriceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price per pack (₹)',
              prefixIcon: Icon(Icons.currency_rupee)),
          ).animate().fadeIn(delay: 280.ms).slideX(begin: -0.05, end: 0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _cigsPerPackCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cigs per pack',
              prefixIcon: Icon(Icons.view_module_outlined)),
          ).animate().fadeIn(delay: 320.ms).slideX(begin: -0.05, end: 0),
        ),
      ]),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        initialValue: _firstSmokeAfterWaking,
        dropdownColor: AppColors.cardDark,
        decoration: const InputDecoration(
          labelText: 'First smoke after waking',
          prefixIcon: Icon(Icons.access_time)),
        items: ['Within 5 minutes', 'Within 30 minutes', 'Within 1 hour', 'After 1 hour']
            .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => _firstSmokeAfterWaking = v!),
      ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.05, end: 0),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        initialValue: _currentGoal,
        dropdownColor: AppColors.cardDark,
        decoration: const InputDecoration(
          labelText: 'Your current goal',
          prefixIcon: Icon(Icons.flag_outlined)),
        items: ['Quit completely', 'Gradually reduce', 'Understand my habits']
            .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => _currentGoal = v!),
      ).animate().fadeIn(delay: 480.ms).slideX(begin: -0.05, end: 0),
    ],
  );

  Widget _triggersStep() => _stepContainer(
    icon: Icons.psychology_outlined,
    title: 'What Makes You Smoke?',
    subtitle: 'Select all that apply. We\'ll use this to suggest the right support at the right time.',
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: AppConstants.triggerOptions.asMap().entries.map((entry) {
          final selected = _selectedTriggers.contains(entry.value);
          return FilterChip(
            label: Text(entry.value),
            selected: selected,
            onSelected: (v) => setState(() =>
                v ? _selectedTriggers.add(entry.value) : _selectedTriggers.remove(entry.value)),
            selectedColor: AppColors.teal.withValues(alpha: 0.25),
            checkmarkColor: AppColors.mintGreen,
          ).animate()
              .fadeIn(delay: (150 + entry.key * 40).ms, duration: 300.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
        }).toList(),
      ),
      if (_selectedTriggers.isEmpty) ...[
        const SizedBox(height: 12),
        _infoBox('You can skip this — triggers can be updated anytime from your profile.'),
      ],
    ],
  );

  Widget _reasonsStep() => _stepContainer(
    icon: Icons.favorite_outline,
    title: 'Why Do You Want to Quit?',
    subtitle: 'Your personal reasons are your strongest motivation.',
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: AppConstants.quitReasonOptions.asMap().entries.map((entry) {
          final selected = _selectedReasons.contains(entry.value);
          return FilterChip(
            label: Text(entry.value),
            selected: selected,
            onSelected: (v) => setState(() =>
                v ? _selectedReasons.add(entry.value) : _selectedReasons.remove(entry.value)),
            selectedColor: AppColors.teal.withValues(alpha: 0.25),
            checkmarkColor: AppColors.mintGreen,
          ).animate()
              .fadeIn(delay: (150 + entry.key * 40).ms, duration: 300.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
        }).toList(),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _personalReasonCtrl,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Write your personal reason (optional)',
          hintText: 'e.g. I want to stop smoking so I can play with my children...',
          prefixIcon: Icon(Icons.edit_note_outlined),
          alignLabelWithHint: true,
        ),
      ).animate().fadeIn(delay: 500.ms),
    ],
  );

  Widget _reviewStep() {
    final cigs = int.tryParse(_cigsPerDayCtrl.text) ?? 10;
    final price = double.tryParse(_packPriceCtrl.text) ?? 250.0;
    final perPack = int.tryParse(_cigsPerPackCtrl.text) ?? 20;
    final dailyCost = (cigs / perPack) * price;

    return _stepContainer(
      icon: Icons.auto_awesome,
      title: 'Your Personalized Plan',
      subtitle: 'Review your settings before we save them.',
      children: [
        _reviewCard('📊', 'Baseline',
            '$cigs cigarettes/day · ₹${dailyCost.toStringAsFixed(0)}/day', 0),
        _reviewCard('🎯', 'Goal', _currentGoal, 1),
        _reviewCard('⚡', 'Key Triggers',
            _selectedTriggers.isEmpty
                ? 'Not set (you can add later)'
                : _selectedTriggers.take(3).join(', '), 2),
        _reviewCard('💪', 'Why Quit',
            _selectedReasons.isEmpty
                ? 'Not set (you can add later)'
                : _selectedReasons.take(3).join(', '), 3),
        _reviewCard('💰', 'Potential Monthly Saving',
            '₹${(dailyCost * 30).toStringAsFixed(0)} at current rate', 4),
        const SizedBox(height: 12),
        _infoBox(
          'These are your starting settings based on your answers. '
          'After logging in, your real data will build from zero — '
          'no fake history will be shown.',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, color: AppColors.amber, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tapping "Complete & Go to Login" saves your settings, then asks you to sign in with your email and password.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.amber, height: 1.5),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Widget _reviewCard(String emoji, String label, String value, int index) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
              const SizedBox(height: 3),
              Text(value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ]),
    ).animate()
        .fadeIn(delay: (200 + index * 100).ms, duration: 400.ms)
        .slideX(begin: 0.1, end: 0);
  }

  Widget _infoBox(String text) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.teal.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline, color: AppColors.teal, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.teal, height: 1.5)),
      ),
    ]),
  ).animate().fadeIn(delay: 600.ms);

  Widget _stepContainer({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Icon(icon, size: 38, color: AppColors.teal)
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.headlineMedium)
              .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 6),
          Text(subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryDark))
              .animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 24),
          ...children,
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Finish — save onboarding data to backend then go to login
  // -------------------------------------------------------------------------
  Future<void> _finish() async {
    setState(() { _saving = true; _saveError = null; });

    final payload = {
      'preferred_name': _nameCtrl.text.trim().isEmpty ? 'Friend' : _nameCtrl.text.trim(),
      'cigarettes_per_day': int.tryParse(_cigsPerDayCtrl.text) ?? 10,
      'cigarettes_per_pack': int.tryParse(_cigsPerPackCtrl.text) ?? 20,
      'price_per_pack': double.tryParse(_packPriceCtrl.text) ?? 250.0,
      'currency': 'INR',
      'first_smoke_after_waking': _firstSmokeAfterWaking,
      'current_goal': _goalKey(_currentGoal),
      'triggers': _selectedTriggers.toList(),
      'quit_reasons': _selectedReasons.toList(),
      'personal_reason_text': _personalReasonCtrl.text.trim(),
    };

    final success = await ref.read(authStateProvider.notifier)
        .completeOnboarding(payload);

    setState(() => _saving = false);

    if (success && mounted) {
      // Show success snackbar and go to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Account set up! Please sign in to start your journey.'),
          backgroundColor: AppColors.teal,
          duration: Duration(seconds: 4),
        ),
      );
      context.go('/login');
    } else if (mounted) {
      setState(() =>
          _saveError = 'Could not save your settings. Check your connection and try again.');
    }
  }

  String _goalKey(String goal) {
    switch (goal) {
      case 'Quit completely': return 'quit';
      case 'Understand my habits': return 'understand';
      default: return 'reduce';
    }
  }
}
