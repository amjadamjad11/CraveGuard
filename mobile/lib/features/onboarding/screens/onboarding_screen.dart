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

  // Step 1: Profile
  final _nameCtrl = TextEditingController(text: 'Friend');
  String _language = 'English';

  // Step 2: Habits
  final _cigsPerDayCtrl = TextEditingController(text: '10');
  final _packPriceCtrl = TextEditingController(text: '250');
  String _firstSmokeAfterWaking = 'Within 30 minutes';
  String _currentGoal = 'Gradually reduce';

  // Step 3: Triggers
  final Set<String> _selectedTriggers = {};

  // Step 4: Quit reasons
  final Set<String> _selectedReasons = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0 ? () {
                        _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } : () => context.go('/login'),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Row(
                        children: List.generate(5, (i) => Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: i <= _currentPage ? AppColors.teal : AppColors.navyLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )),
                      ),
                    ),
                    TextButton(
                      onPressed: _finish,
                      child: Text(_currentPage == 4 ? 'Done' : 'Skip',
                        style: const TextStyle(color: AppColors.textSecondaryDark)),
                    ),
                  ],
                ),
              ),
              // Pages
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [_profileStep(), _habitsStep(), _triggersStep(), _reasonsStep(), _planStep()],
                ),
              ),
              // Next button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 4) {
                        _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else {
                        _finish();
                      }
                    },
                    child: Text(_currentPage < 4 ? 'Continue' : 'Start My Journey'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileStep() => _stepContainer(
    icon: Icons.person_outline,
    title: 'Welcome to CraveGuard',
    subtitle: 'Let\'s get to know you a little.',
    children: [
      TextField(controller: _nameCtrl,
        decoration: const InputDecoration(labelText: 'What should we call you?', prefixIcon: Icon(Icons.badge_outlined)))
          .animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: -0.05, end: 0),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _language, dropdownColor: AppColors.cardDark,
        decoration: const InputDecoration(labelText: 'Language', prefixIcon: Icon(Icons.language)),
        items: ['English', 'Hindi', 'Tamil', 'Telugu'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
        onChanged: (v) => setState(() => _language = v!),
      ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: -0.05, end: 0),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.teal, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('Your information stays private and is only used to personalize your experience.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.teal))),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
    ],
  );

  Widget _habitsStep() => _stepContainer(
    icon: Icons.smoking_rooms,
    title: 'Understanding Your Habits',
    subtitle: 'This helps us set a meaningful baseline. You can update anytime.',
    children: [
      TextField(controller: _cigsPerDayCtrl, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Cigarettes per day', prefixIcon: Icon(Icons.filter_1)))
          .animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: -0.05, end: 0),
      const SizedBox(height: 16),
      TextField(controller: _packPriceCtrl, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Price per pack (₹)', prefixIcon: Icon(Icons.currency_rupee)))
          .animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: -0.05, end: 0),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _firstSmokeAfterWaking, dropdownColor: AppColors.cardDark,
        decoration: const InputDecoration(labelText: 'First smoke after waking', prefixIcon: Icon(Icons.access_time)),
        items: ['Within 5 minutes', 'Within 30 minutes', 'Within 1 hour', 'After 1 hour']
            .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => _firstSmokeAfterWaking = v!),
      ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideX(begin: -0.05, end: 0),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _currentGoal, dropdownColor: AppColors.cardDark,
        decoration: const InputDecoration(labelText: 'Your current goal', prefixIcon: Icon(Icons.flag)),
        items: ['Quit completely', 'Gradually reduce', 'Understand my habits']
            .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => _currentGoal = v!),
      ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(begin: -0.05, end: 0),
    ],
  );

  Widget _triggersStep() => _stepContainer(
    icon: Icons.psychology_outlined,
    title: 'What Makes You Smoke?',
    subtitle: 'Select all that apply. This helps us suggest the right support at the right time.',
    children: [
      Wrap(
        spacing: 8, runSpacing: 8,
        children: AppConstants.triggerOptions.asMap().entries.map((entry) => FilterChip(
          label: Text(entry.value),
          selected: _selectedTriggers.contains(entry.value),
          onSelected: (v) => setState(() => v ? _selectedTriggers.add(entry.value) : _selectedTriggers.remove(entry.value)),
          selectedColor: AppColors.teal.withValues(alpha: 0.3),
          checkmarkColor: AppColors.mintGreen,
        ).animate().fadeIn(delay: (150 + entry.key * 50).ms, duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1))).toList(),
      ),
    ],
  );

  Widget _reasonsStep() => _stepContainer(
    icon: Icons.favorite_outline,
    title: 'Why Do You Want to Quit?',
    subtitle: 'Your personal reasons are the strongest motivation.',
    children: [
      Wrap(
        spacing: 8, runSpacing: 8,
        children: AppConstants.quitReasonOptions.asMap().entries.map((entry) => FilterChip(
          label: Text(entry.value),
          selected: _selectedReasons.contains(entry.value),
          onSelected: (v) => setState(() => v ? _selectedReasons.add(entry.value) : _selectedReasons.remove(entry.value)),
          selectedColor: AppColors.teal.withValues(alpha: 0.3),
          checkmarkColor: AppColors.mintGreen,
        ).animate().fadeIn(delay: (150 + entry.key * 50).ms, duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1))).toList(),
      ),
    ],
  );

  Widget _planStep() {
    final cigs = int.tryParse(_cigsPerDayCtrl.text) ?? 10;
    final price = double.tryParse(_packPriceCtrl.text) ?? 250;
    final dailyCost = (cigs / 20) * price;

    final planItems = [
      _PlanData('📊', 'Baseline', '$cigs cigarettes/day • ₹${dailyCost.toStringAsFixed(0)}/day'),
      _PlanData('🎯', 'Goal', _currentGoal),
      _PlanData('⚡', 'Key Triggers', _selectedTriggers.isEmpty ? 'Not set yet' : _selectedTriggers.take(3).join(', ')),
      _PlanData('💪', 'Motivation', _selectedReasons.isEmpty ? 'Not set yet' : _selectedReasons.take(3).join(', ')),
      _PlanData('💰', 'Potential Savings', '₹${(dailyCost * 0.3 * 30).toStringAsFixed(0)}/month if you reduce by 30%'),
    ];

    return _stepContainer(
      icon: Icons.auto_awesome,
      title: 'Your Personalized Plan',
      subtitle: 'Here\'s what we\'ve prepared based on your answers.',
      children: [
        ...planItems.asMap().entries.map((entry) =>
          _planCard(entry.value.emoji, entry.value.label, entry.value.value, entry.key),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Text('These are initial estimates based on your answers. They\'ll become more accurate as you track.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.teal)),
        ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
      ],
    );
  }

  Widget _planCard(String emoji, String label, String value, int index) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    ),
  ).animate().fadeIn(delay: (200 + index * 150).ms, duration: 400.ms).slideX(begin: 0.1, end: 0);

  Widget _stepContainer({required IconData icon, required String title, required String subtitle, required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Icon(icon, size: 40, color: AppColors.teal)
              .animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineMedium)
              .animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark))
              .animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 28),
          ...children,
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _finish() {
    ref.read(onboardingCompleteProvider.notifier).state = true;
    context.go('/home');
  }
}

class _PlanData {
  final String emoji;
  final String label;
  final String value;
  const _PlanData(this.emoji, this.label, this.value);
}
