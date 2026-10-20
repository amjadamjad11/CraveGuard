import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../services/demo_service.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(demoModeProvider)) {
        final demo = DemoService();
        ref.read(weeklySmokingDataProvider.notifier).state = demo.weeklySmokingData;
        ref.read(topTriggersProvider.notifier).state = demo.topTriggers;
        ref.read(savingsDataProvider.notifier).state = demo.savingsData;
        ref.read(milestonesProvider.notifier).state = demo.milestones;
        ref.read(dailySummaryProvider.notifier).state = demo.dailySummary;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final weeklyData = ref.watch(weeklySmokingDataProvider);
    final triggers = ref.watch(topTriggersProvider);
    final savings = ref.watch(savingsDataProvider);
    final milestones = ref.watch(milestonesProvider);
    final summary = ref.watch(dailySummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Today summary row
          Row(
            children: [
              Expanded(child: _statBox('Today', '${summary['cigarettes_smoked'] ?? 0}', 'cigarettes', AppColors.coral)),
              const SizedBox(width: 10),
              Expanded(child: _statBox('Resisted', '${summary['cravings_resisted'] ?? 0}', 'cravings', AppColors.mintGreen)),
              const SizedBox(width: 10),
              Expanded(child: _statBox('Avg', '${(summary['avg_craving_intensity'] ?? 0).toStringAsFixed(1)}', 'intensity', AppColors.amber)),
            ],
          ),
          const SizedBox(height: 20),
          // Weekly chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly Smoking Trend', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weeklyData.asMap().entries.map((entry) {
                      final d = entry.value;
                      final count = (d['count'] as num?) ?? 0;
                      final maxH = 120.0;
                      final h = (count / 20 * maxH).clamp(4.0, maxH);
                      final dateStr = (d['date'] as String?) ?? '';
                      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      final dayLabel = entry.key < dayNames.length ? dayNames[entry.key] : dateStr.split('-').last;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('$count', style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                height: h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                    colors: [count > 12 ? AppColors.coral : AppColors.teal, count > 12 ? AppColors.softCoral : AppColors.mintGreen]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(dayLabel, style: const TextStyle(fontSize: 10, color: AppColors.textTertiaryDark)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Triggers breakdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trigger Analysis', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ...triggers.asMap().entries.map((entry) {
                  final t = entry.value;
                  final total = triggers.fold<int>(0, (sum, t) => sum + ((t['count'] as int?) ?? 0));
                  final pct = total > 0 ? ((t['count'] as int?) ?? 0) / total : 0.0;
                  final colors = [AppColors.coral, AppColors.amber, AppColors.teal, AppColors.lavender, AppColors.mintGreen];
                  final color = colors[entry.key % colors.length];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(t['trigger'] ?? '', style: const TextStyle(fontSize: 13)),
                            Text('${(pct * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppColors.navyLight,
                          color: color,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Savings summary
          GestureDetector(
            onTap: () => context.push('/savings'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.mintGradient, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Saved', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('${savings['currency'] ?? '₹'}${((savings['total_savings'] as num?) ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                      Text('${savings['cigarettes_avoided'] ?? 0} cigarettes avoided',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  )),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Milestones
          Text('Milestones', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...milestones.map((m) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: m['achieved'] == true ? AppColors.teal.withValues(alpha: 0.1) : AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: m['achieved'] == true ? Border.all(color: AppColors.teal.withValues(alpha: 0.3)) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: m['achieved'] == true ? AppColors.mintGreen.withValues(alpha: 0.2) : AppColors.navyLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    m['achieved'] == true ? Icons.emoji_events : Icons.lock_outline,
                    color: m['achieved'] == true ? AppColors.mintGreen : AppColors.textTertiaryDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['title'] ?? '', style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: m['achieved'] == true ? AppColors.textPrimaryDark : AppColors.textTertiaryDark)),
                    Text(m['description'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                  ],
                )),
                if (m['achieved'] == true)
                  const Icon(Icons.check_circle, color: AppColors.mintGreen, size: 20),
              ],
            ),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, String unit, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)),
    child: Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
        Text(unit, style: const TextStyle(fontSize: 10, color: AppColors.textTertiaryDark)),
      ],
    ),
  );
}
