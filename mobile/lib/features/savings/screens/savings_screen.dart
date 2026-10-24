import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../services/demo_service.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});
  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  Timer? _timer;
  Duration _smokeFree = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(demoModeProvider)) {
        ref.read(savingsDataProvider.notifier).state = DemoService().savingsData;
        ref.read(savingsGoalsProvider.notifier).state = DemoService().savingsGoals;
      }
      final events = ref.read(smokingEventsProvider);
      DateTime smokeFreeSince;
      if (events.isNotEmpty) {
        final lastTimeStr = events.first['event_time'] as String?;
        smokeFreeSince = lastTimeStr != null ? DateTime.tryParse(lastTimeStr) ?? DateTime.now() : DateTime.now();
      } else {
        smokeFreeSince = DateTime.now();
      }
      _smokeFree = DateTime.now().difference(smokeFreeSince);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _smokeFree = DateTime.now().difference(smokeFreeSince);
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savings = ref.watch(savingsDataProvider);
    final goals = ref.watch(savingsGoalsProvider);
    final currency = savings['currency'] ?? '₹';

    return Scaffold(
      appBar: AppBar(title: const Text('Money Saved')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Smoke-free countdown
          if (_smokeFree.inSeconds > 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.mintGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mintGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.smoke_free, color: AppColors.mintGreen, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Smoke-free for', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                        const SizedBox(height: 2),
                        Text(
                          '${_smokeFree.inDays}d ${_smokeFree.inHours % 24}h ${_smokeFree.inMinutes % 60}m ${_smokeFree.inSeconds % 60}s',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.mintGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0),

          // Total saved hero card with enhanced gradient
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D7377), Color(0xFF14919B), Color(0xFF45DFB1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('Total Estimated Savings', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text('$currency${_fmt(savings['total_savings'])}',
                  style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('${savings['cigarettes_avoided'] ?? 0} cigarettes avoided',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Text('Based on recorded smoking vs baseline', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
          const SizedBox(height: 20),

          // Breakdown cards with staggered animations
          Row(
            children: [
              Expanded(child: _breakdownCard('Today', '$currency${_fmt(savings['daily_savings'])}', Icons.today)
                  .animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.15, end: 0)),
              const SizedBox(width: 10),
              Expanded(child: _breakdownCard('This Week', '$currency${_fmt(savings['weekly_savings'])}', Icons.date_range)
                  .animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.15, end: 0)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _breakdownCard('This Month', '$currency${_fmt(savings['monthly_savings'])}', Icons.calendar_month)
                  .animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.15, end: 0)),
              const SizedBox(width: 10),
              Expanded(child: _breakdownCard('Yearly Est.', '$currency${_fmt(savings['yearly_projection'])}', Icons.calendar_today)
                  .animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.15, end: 0)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.teal),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Daily baseline: $currency${_fmt(savings['baseline_daily_cost'])} → Current: $currency${_fmt(savings['current_daily_cost'])}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Savings goals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Savings Goals', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: _showAddGoalSheet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Goal'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...goals.map((g) => _goalCard(g, currency)),
          if (goals.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)),
              child: const Column(
                children: [
                  Icon(Icons.savings, size: 48, color: AppColors.textTertiaryDark),
                  SizedBox(height: 12),
                  Text('No savings goals yet', style: TextStyle(color: AppColors.textSecondaryDark)),
                  SizedBox(height: 4),
                  Text('Set a goal to visualize what your savings can buy!',
                    style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.amber),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'These are estimated savings based on your tracked smoking data. This is a tracking feature, not a bank account.',
                  style: TextStyle(fontSize: 11, color: AppColors.amber))),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _breakdownCard(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.teal),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
      ],
    ),
  );

  Widget _goalCard(Map<String, dynamic> goal, String currency) {
    final target = (goal['target_amount'] as num?) ?? 1;
    final current = (goal['current_amount'] as num?) ?? 0;
    final pct = (current / target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.flag, color: AppColors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('$currency${current.toStringAsFixed(0)} / $currency${target.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                ],
              )),
              Text('${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.w700, color: pct >= 1 ? AppColors.mintGreen : AppColors.teal)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: pct, backgroundColor: AppColors.navyLight, color: AppColors.mintGreen,
            minHeight: 8, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }

  void _showAddGoalSheet() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Savings Goal', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'What are you saving for?', prefixIcon: Icon(Icons.flag))),
            const SizedBox(height: 12),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target amount (₹)', prefixIcon: Icon(Icons.currency_rupee))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () {
                if (titleCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                  final goals = List<Map<String, dynamic>>.from(ref.read(savingsGoalsProvider));
                  goals.add({
                    'id': goals.length + 1, 'title': titleCtrl.text,
                    'target_amount': double.tryParse(amountCtrl.text) ?? 1000,
                    'current_amount': 0.0, 'icon': 'flag', 'is_completed': false,
                  });
                  ref.read(savingsGoalsProvider.notifier).state = goals;
                  Navigator.pop(context);
                }
              }, child: const Text('Create Goal')),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic v) => v != null ? (v as num).toStringAsFixed(0) : '0';
}

