import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../services/demo_service.dart';
import '../../../providers/app_providers.dart';
import '../../../services/location_service.dart';

class CravingFlowScreen extends ConsumerStatefulWidget {
  const CravingFlowScreen({super.key});
  @override
  ConsumerState<CravingFlowScreen> createState() => _CravingFlowScreenState();
}

class _CravingFlowScreenState extends ConsumerState<CravingFlowScreen> with TickerProviderStateMixin {
  int _step = 0;
  double _intensity = 5;
  String? _feeling;
  String? _trigger;
  bool _helped = false;

  // Breathing animation controller
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // 4s in + 4s out
    )..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Craving Support'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _intensityStep();
      case 1: return _feelingStep();
      case 2: return _triggerStep();
      case 3: return _interventionStep();
      case 4: return _feedbackStep();
      default: return _intensityStep();
    }
  }

  Color _intensityColor() {
    if (_intensity < 4) return AppColors.mintGreen;
    if (_intensity < 7) return AppColors.amber;
    return AppColors.coral;
  }

  Widget _intensityStep() => _stepLayout(
    key: const ValueKey(0),
    icon: Icons.local_fire_department,
    iconColor: AppColors.amber,
    title: 'How strong is your craving?',
    subtitle: 'Rate from 1 (mild) to 10 (overwhelming)',
    child: Column(
      children: [
        // Animated intensity display with color-coded ring
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _intensityColor().withValues(alpha: 0.1),
            border: Border.all(color: _intensityColor(), width: 3),
            boxShadow: [
              BoxShadow(
                color: _intensityColor().withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text('${_intensity.round()}', style: TextStyle(
              fontSize: 40, fontWeight: FontWeight.w700,
              color: _intensityColor())),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _intensity < 4 ? 'Mild – You can ride this out' : _intensity < 7 ? 'Moderate – Try a distraction' : 'Strong – Let\'s work through this',
            key: ValueKey(_intensity < 4 ? 'mild' : _intensity < 7 ? 'mod' : 'strong'),
            style: TextStyle(color: _intensityColor(), fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),
        // Gradient slider track
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 10,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            activeTrackColor: _intensityColor(),
            inactiveTrackColor: AppColors.navyLight,
            thumbColor: _intensityColor(),
            overlayColor: _intensityColor().withValues(alpha: 0.15),
          ),
          child: Slider(
            value: _intensity, min: 1, max: 10, divisions: 9,
            onChanged: (v) => setState(() => _intensity = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('1', style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 12)),
              Text('10', style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 12)),
            ],
          ),
        ),
      ],
    ),
    onNext: () => setState(() => _step = 1),
  );

  Widget _feelingStep() => _stepLayout(
    key: const ValueKey(1),
    icon: Icons.emoji_emotions,
    iconColor: AppColors.lavender,
    title: 'What are you feeling?',
    subtitle: 'Understanding your emotions helps find the right support',
    child: Wrap(
      spacing: 10, runSpacing: 10,
      children: ['😰 Stressed', '😟 Anxious', '😢 Sad', '😠 Angry', '🥱 Bored', '😴 Tired', '😐 Neutral', '🤷 Not sure'].map((m) =>
        ChoiceChip(
          label: Text(m, style: const TextStyle(fontSize: 14)),
          selected: _feeling == m,
          onSelected: (_) => setState(() => _feeling = m),
          selectedColor: AppColors.teal.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ).toList(),
    ),
    onNext: () => setState(() => _step = 2),
  );

  Widget _triggerStep() => _stepLayout(
    key: const ValueKey(2),
    icon: Icons.bolt,
    iconColor: AppColors.amber,
    title: 'What triggered this?',
    subtitle: 'Tap the most relevant one',
    child: Wrap(
      spacing: 10, runSpacing: 10,
      children: ['Stress', 'Boredom', 'Habit', 'Social Pressure', 'After Meal', 'Coffee/Tea', 'Work', 'Withdrawal', 'Not sure'].map((t) =>
        ChoiceChip(
          label: Text(t, style: const TextStyle(fontSize: 14)),
          selected: _trigger == t,
          onSelected: (_) => setState(() => _trigger = t),
          selectedColor: AppColors.teal.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ).toList(),
    ),
    onNext: () => setState(() => _step = 3),
  );

  Widget _interventionStep() {
    final intervention = DemoService().recommendedIntervention;
    final i = intervention['intervention'] as Map<String, dynamic>? ?? {};

    return _stepLayout(
      key: const ValueKey(3),
      icon: Icons.self_improvement,
      iconColor: AppColors.mintGreen,
      title: 'Try This',
      subtitle: intervention['reason'] as String? ?? '',
      child: Column(
        children: [
          // Breathing animation circle
          AnimatedBuilder(
            animation: _breathAnimation,
            builder: (context, child) {
              final phase = _breathAnimation.value > 0.8 ? 'Breathe In...' : _breathAnimation.value < 0.7 ? 'Breathe Out...' : 'Hold...';
              return Column(
                children: [
                  Container(
                    width: 140 * _breathAnimation.value,
                    height: 140 * _breathAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.mintGreen.withValues(alpha: 0.3),
                          AppColors.teal.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.mintGreen.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.air, size: 36 * _breathAnimation.value, color: AppColors.mintGreen),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(phase,
                    style: const TextStyle(color: AppColors.mintGreen, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.teal.withValues(alpha: 0.2), AppColors.mintGreen.withValues(alpha: 0.1)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(i['name'] ?? 'Breathing Exercise',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.mintGreen)),
                const SizedBox(height: 8),
                Text(i['instructions'] ?? 'Breathe in for 4, hold for 4, out for 6.',
                  style: const TextStyle(color: AppColors.textSecondaryDark, height: 1.5), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text('${i['duration_minutes'] ?? 3} minutes', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      nextLabel: 'I tried it →',
      onNext: () => setState(() => _step = 4),
    );
  }

  Widget _feedbackStep() => _stepLayout(
    key: const ValueKey(4),
    icon: Icons.chat_bubble_outline,
    iconColor: AppColors.teal,
    title: 'Did that help?',
    subtitle: 'Your feedback makes future suggestions better',
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: _feedbackButton('Yes, it helped! 👍', true, AppColors.mintGreen)),
            const SizedBox(width: 12),
            Expanded(child: _feedbackButton('Not really 👎', false, AppColors.coral)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Text(
            'Remember: cravings are temporary. Each one you get through makes you stronger. 💪',
            style: TextStyle(color: AppColors.teal, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
        ),
      ],
    ),
    nextLabel: 'Done',
    onNext: () async {
      final loc = await LocationService().getCurrentPosition();
      ref.read(smokingRepoProvider).logCravingEvent({
        'intensity_before': _intensity.round(),
        'trigger_category': _trigger,
        'feeling': _feeling,
        'intervention_helped': _helped,
        'latitude': loc?.latitude,
        'longitude': loc?.longitude,
      });
      if (mounted) Navigator.pop(context);
    },
  );

  Widget _feedbackButton(String label, bool helpful, Color color) => GestureDetector(
    onTap: () => setState(() => _helped = helpful),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (_helped == helpful && _step == 4) ? color.withValues(alpha: 0.2) : AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (_helped == helpful && _step == 4) ? color : AppColors.navyLight, width: (_helped == helpful && _step == 4) ? 2 : 1),
      ),
      child: Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
    ),
  );

  Widget _stepLayout({
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
    String nextLabel = 'Continue',
    required VoidCallback onNext,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Icon(icon, size: 48, color: iconColor),
                  const SizedBox(height: 20),
                  Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondaryDark), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  child,
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onNext, child: Text(nextLabel)),
          ),
        ],
      ),
    );
  }
}
