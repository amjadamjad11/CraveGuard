import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../services/demo_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final demo = DemoService();
    final isDemo = ref.read(demoModeProvider);
    if (isDemo) {
      ref.read(todaySmokingCountProvider.notifier).state = demo.todaySmokingCount;
      ref.read(weeklySmokingDataProvider.notifier).state = demo.weeklySmokingData;
      ref.read(savingsDataProvider.notifier).state = demo.savingsData;
      ref.read(topTriggersProvider.notifier).state = demo.topTriggers;
      ref.read(dailySummaryProvider.notifier).state = demo.dailySummary;
      ref.read(milestonesProvider.notifier).state = demo.milestones;
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayCount = ref.watch(todaySmokingCountProvider);
    final savings = ref.watch(savingsDataProvider);
    final dailySummary = ref.watch(dailySummaryProvider);
    final topTriggers = ref.watch(topTriggersProvider);
    final isDemo = ref.watch(demoModeProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with greeting
          SliverAppBar(
            expandedHeight: 120, floating: true, pinned: false,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_greeting(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark)),
                            Text(isDemo ? 'Demo User' : 'Friend',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.textPrimaryDark)),
                          ],
                        ),
                        Row(children: [
                          if (isDemo) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                            child: const Text('DEMO', style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => context.push('/settings'),
                          ),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(delegate: SliverChildListDelegate([
              // Today's progress card
              _todayProgressCard(todayCount, dailySummary),
              const SizedBox(height: 16),
              // Quick action buttons
              _quickActions(),
              const SizedBox(height: 20),
              // Money saved card
              _savingsCard(savings),
              const SizedBox(height: 20),
              // Top triggers
              if (topTriggers.isNotEmpty) _triggersCard(topTriggers),
              if (topTriggers.isNotEmpty) const SizedBox(height: 20),
              // Quick links
              _quickLinksSection(),
              const SizedBox(height: 100),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _todayProgressCard(int todayCount, Map<String, dynamic> summary) {
    final goal = 15; // baseline
    final percentage = todayCount >= goal ? 1.0 : todayCount / goal;
    final cravingsResisted = summary['cravings_resisted'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.cardDark, AppColors.cardDarkElevated]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navyLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Progress ring
              SizedBox(
                width: 90, height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90, height: 90,
                      child: CircularProgressIndicator(
                        value: 1.0 - percentage.clamp(0.0, 1.0),
                        strokeWidth: 8,
                        backgroundColor: AppColors.navyLight,
                        color: percentage < 0.5 ? AppColors.mintGreen : percentage < 0.8 ? AppColors.amber : AppColors.coral,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$todayCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                        Text('of $goal', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Progress", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _miniStat(Icons.smoking_rooms, '$todayCount cigarettes', AppColors.coral),
                    const SizedBox(height: 4),
                    _miniStat(Icons.shield_outlined, '$cravingsResisted cravings resisted', AppColors.mintGreen),
                    const SizedBox(height: 4),
                    _miniStat(Icons.trending_down, todayCount < goal
                        ? '${goal - todayCount} below baseline'
                        : '${todayCount - goal} above baseline',
                        todayCount <= goal ? AppColors.mintGreen : AppColors.coral),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String text, Color color) => Row(
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: TextStyle(fontSize: 12, color: color))),
    ],
  );

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(child: _actionButton('I Smoked', Icons.smoking_rooms, AppColors.coral, () => _showQuickLog())),
        const SizedBox(width: 10),
        Expanded(child: _actionButton('Craving', Icons.local_fire_department, AppColors.amber, () => context.push('/craving-support'))),
        const SizedBox(width: 10),
        Expanded(child: _actionButton('I Resisted!', Icons.emoji_events, AppColors.mintGreen, () => _logResisted())),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _savingsCard(Map<String, dynamic> savings) {
    final currency = savings['currency'] ?? '₹';
    final daily = savings['daily_savings'] ?? 0;
    final total = savings['total_savings'] ?? 0;
    final avoided = savings['cigarettes_avoided'] ?? 0;

    return GestureDetector(
      onTap: () => context.push('/savings'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.mintGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Money Saved', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('$currency${(total as num).toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('$currency${(daily as num).toStringAsFixed(0)} today • $avoided cigarettes avoided',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _triggersCard(List<Map<String, dynamic>> triggers) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Top Triggers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...triggers.take(3).map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: t == triggers.first ? AppColors.coral : t == triggers[1] ? AppColors.amber : AppColors.teal,
                    shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(t['trigger'] ?? '', style: const TextStyle(fontSize: 13))),
                Text('${t['count']}x', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _quickLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Links', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _linkCard(Icons.favorite, 'Motivation', AppColors.lavender, () => context.push('/motivation-vault'))),
            const SizedBox(width: 10),
            Expanded(child: _linkCard(Icons.people, 'Support', AppColors.amber, () => context.push('/trusted-contacts'))),
            const SizedBox(width: 10),
            Expanded(child: _linkCard(Icons.savings, 'Goals', AppColors.mintGreen, () => context.push('/savings'))),
          ],
        ),
      ],
    );
  }

  Widget _linkCard(IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );

  void _showQuickLog() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => _QuickLogSheet(
      onLogged: () {
        ref.read(todaySmokingCountProvider.notifier).state++;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Smoking event recorded. No judgment — tracking helps.')));
      },
    ));
  }

  void _logResisted() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Amazing! 🎉 You resisted a craving. That takes real strength.')));
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _QuickLogSheet extends StatefulWidget {
  final VoidCallback onLogged;
  const _QuickLogSheet({required this.onLogged});
  @override
  State<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<_QuickLogSheet> {
  String? _trigger;
  String? _mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Quick Log', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('No judgment. Tracking helps you understand your patterns.', style: TextStyle(color: AppColors.textSecondaryDark)),
          const SizedBox(height: 20),
          const Text('How are you feeling?', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['😐 Neutral', '😰 Stressed', '😟 Anxious', '😢 Sad', '😠 Angry', '🥱 Bored'].map((m) => ChoiceChip(
              label: Text(m, style: const TextStyle(fontSize: 13)),
              selected: _mood == m,
              onSelected: (_) => setState(() => _mood = m),
              selectedColor: AppColors.teal.withValues(alpha: 0.3),
            )).toList(),
          ),
          const SizedBox(height: 16),
          const Text('What triggered this?', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['Stress', 'Boredom', 'Habit', 'Social', 'After meal', 'Craving'].map((t) => ChoiceChip(
              label: Text(t, style: const TextStyle(fontSize: 13)),
              selected: _trigger == t,
              onSelected: (_) => setState(() => _trigger = t),
              selectedColor: AppColors.teal.withValues(alpha: 0.3),
            )).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: widget.onLogged, child: const Text('Record')),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
