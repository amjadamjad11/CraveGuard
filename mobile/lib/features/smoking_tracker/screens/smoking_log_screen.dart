import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../services/demo_service.dart';

class SmokingLogScreen extends ConsumerStatefulWidget {
  const SmokingLogScreen({super.key});
  @override
  ConsumerState<SmokingLogScreen> createState() => _SmokingLogScreenState();
}

class _SmokingLogScreenState extends ConsumerState<SmokingLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(demoModeProvider)) {
        ref.read(smokingEventsProvider.notifier).state = DemoService().smokingEvents;
        ref.read(weeklySmokingDataProvider.notifier).state = DemoService().weeklySmokingData;
      }
    });
  }

  /// Compute streak of consecutive days below baseline (e.g., below 10)
  int _computeStreak(List<Map<String, dynamic>> weeklyData) {
    const baseline = 10;
    int streak = 0;
    // Walk backwards from the most recent day
    for (int i = weeklyData.length - 1; i >= 0; i--) {
      final count = (weeklyData[i]['count'] as num?) ?? 0;
      if (count < baseline) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(smokingEventsProvider);
    final weeklyData = ref.watch(weeklySmokingDataProvider);
    final streak = _computeStreak(weeklyData);

    return Scaffold(
      appBar: AppBar(title: const Text('My Patterns')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Streak indicator
          if (streak > 1)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.mintGreen.withValues(alpha: 0.15), AppColors.teal.withValues(alpha: 0.1)],
                ),
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
                    child: const Icon(Icons.local_fire_department, color: AppColors.mintGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔥 $streak-Day Streak!',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.mintGreen)),
                        const SizedBox(height: 2),
                        const Text('Consecutive days below your baseline. Keep going!',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0),

          // Weekly overview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly Overview', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weeklyData.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final d = entry.value;
                      final count = (d['count'] as num?) ?? 0;
                      const maxH = 100.0;
                      final h = (count / 20 * maxH).clamp(4.0, maxH);
                      final day = (d['date'] as String?)?.split('-').last ?? '';
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('$count', style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
                              const SizedBox(height: 4),
                              Container(
                                height: h,
                                decoration: BoxDecoration(
                                  color: count > 12 ? AppColors.coral : count > 8 ? AppColors.amber : AppColors.mintGreen,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ).animate().scaleY(begin: 0, end: 1, delay: (100 + idx * 80).ms, duration: 500.ms, curve: Curves.easeOutBack, alignment: Alignment.bottomCenter),
                              const SizedBox(height: 4),
                              Text(day, style: const TextStyle(fontSize: 10, color: AppColors.textTertiaryDark)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          // Recent events
          Text('Recent Events', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Icon(Icons.smoke_free, size: 48, color: AppColors.textTertiaryDark),
                  const SizedBox(height: 12),
                  const Text('No events recorded yet', style: TextStyle(color: AppColors.textSecondaryDark)),
                  const SizedBox(height: 4),
                  const Text('Use the "I Smoked" button on Home to start tracking',
                    style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ...events.take(20).toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final e = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.smoking_rooms, color: AppColors.coral, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e['trigger_category'] ?? 'No trigger', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text('${e['mood'] ?? ''} • Intensity: ${e['craving_intensity'] ?? '-'}/10',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                        ],
                      ),
                    ),
                    Text(_formatTime(e['event_time']), style: const TextStyle(fontSize: 11, color: AppColors.textTertiaryDark)),
                  ],
                ),
              ).animate().fadeIn(delay: (100 + idx * 60).ms, duration: 350.ms).slideX(begin: 0.05, end: 0);
            }),
        ],
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }
}
