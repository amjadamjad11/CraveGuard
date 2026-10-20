import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final isDemo = ref.watch(demoModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile section
          _sectionHeader(context, 'Profile'),
          _settingsTile(Icons.person_outline, 'Edit Profile', 'Update your habits and goals', () => context.push('/onboarding')),
          _settingsTile(Icons.psychology, 'My Triggers', 'Update your trigger survey', () => context.push('/onboarding')),
          _settingsTile(Icons.flag_outlined, 'Smoking Goal', 'Change your goal or quit date', () {}),
          const SizedBox(height: 20),

          // Appearance
          _sectionHeader(context, 'Appearance'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.dark_mode, color: AppColors.teal),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(isDark ? 'On' : 'Off', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                  ],
                )),
                Switch(value: isDark, onChanged: (v) => ref.read(isDarkModeProvider.notifier).state = v),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Demo mode
          _sectionHeader(context, 'Demo Mode'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDemo ? AppColors.amber.withValues(alpha: 0.1) : AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: isDemo ? Border.all(color: AppColors.amber.withValues(alpha: 0.3)) : null,
            ),
            child: Row(
              children: [
                Icon(Icons.science, color: isDemo ? AppColors.amber : AppColors.textSecondaryDark),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Demo Mode', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(isDemo ? 'Using sample data' : 'Connected to backend',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                  ],
                )),
                Switch(value: isDemo, onChanged: (v) {
                  ref.read(demoModeProvider.notifier).state = v;
                  ref.read(apiServiceProvider).isDemoMode = v;
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Privacy
          _sectionHeader(context, 'Privacy & Data'),
          _settingsTile(Icons.shield_outlined, 'Privacy Settings', 'Manage consent and data', () {}),
          _settingsTile(Icons.notifications_outlined, 'Notifications', 'Manage reminders', () {}),
          _settingsTile(Icons.download, 'Export Data', 'Download your data', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data export not yet implemented.')));
          }),
          _settingsTile(Icons.delete_outline, 'Delete Account', 'Permanently delete all data', () {
            showDialog(context: context, builder: (_) => AlertDialog(
              title: const Text('Delete Account?'),
              content: const Text('This will permanently delete all your data. This cannot be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(
                  onPressed: () { Navigator.pop(context); ref.read(authStateProvider.notifier).logout(); context.go('/login'); },
                  child: const Text('Delete', style: TextStyle(color: AppColors.error))),
              ],
            ));
          }, danger: true),
          const SizedBox(height: 20),

          // About
          _sectionHeader(context, 'About & Resources'),
          _settingsTile(
            Icons.info_outline,
            'About CraveGuard',
            'Version, quitline numbers, health resources & privacy',
            () => context.push('/about'),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authStateProvider.notifier).logout();
                context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppColors.coral),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.coral)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.coral),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.teal)),
  );

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback onTap, {bool danger = false}) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(icon, color: danger ? AppColors.coral : AppColors.textSecondaryDark),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: danger ? AppColors.coral : null)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiaryDark),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: AppColors.cardDark,
      onTap: onTap,
    ),
  );
}
