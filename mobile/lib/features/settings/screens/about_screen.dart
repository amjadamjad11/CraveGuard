import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About CraveGuard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // App branding
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.mintGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded, size: 44, color: Colors.white),
                ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text('CraveGuard', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.mintGreen, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Version 1.0.0', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('AI-Powered Smoking Cessation Support',
                  style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Emergency Helpline
          _sectionCard(
            context,
            icon: Icons.phone_in_talk,
            iconColor: AppColors.coral,
            title: 'Need Immediate Help?',
            children: [
              _helplineRow(context, 'National Tobacco Quitline', '1800-11-2356', 'Free, 24/7 support'),
              const SizedBox(height: 8),
              _helplineRow(context, 'iCALL (Mental Health)', '9152987821', 'Mon–Sat, 8am–10pm'),
              const SizedBox(height: 12),
              const Text(
                'If you are in crisis or experiencing a medical emergency, please call your local emergency services immediately.',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiaryDark, height: 1.5),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 12),

          // Health Resources
          _sectionCard(
            context,
            icon: Icons.health_and_safety,
            iconColor: AppColors.mintGreen,
            title: 'Health Resources',
            children: [
              _resourceLink(context, 'WHO – Tobacco Free Initiative', 'https://www.who.int/health-topics/tobacco'),
              _resourceLink(context, 'Smokefree.gov', 'https://smokefree.gov'),
              _resourceLink(context, 'National Institute of Mental Health', 'https://www.nimhans.ac.in'),
            ],
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 12),

          // Privacy Policy
          _sectionCard(
            context,
            icon: Icons.privacy_tip_outlined,
            iconColor: AppColors.lavender,
            title: 'Privacy & Data',
            children: [
              const Text(
                '• Your data is stored locally on your device and optionally synced to your account.\n'
                '• We do not sell or share your personal health data with third parties.\n'
                '• Location data (if enabled) is used only for risk zone alerts and never leaves your device.\n'
                '• You can export or delete all your data at any time from Settings.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.7),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 12),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text('Disclaimer', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.amber)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'CraveGuard is not a medical device and is not intended to diagnose, treat, cure, or prevent any disease or medical condition. '
                  'It is a supportive tool designed to complement — not replace — professional medical advice, diagnosis, or treatment. '
                  'Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition or addiction treatment.',
                  style: TextStyle(fontSize: 12, color: AppColors.amber, height: 1.6),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
          const SizedBox(height: 12),

          // Credits
          _sectionCard(
            context,
            icon: Icons.people_outline,
            iconColor: AppColors.teal,
            title: 'Credits',
            children: [
              const Text(
                'Built with ❤️ for the hackathon.\n\n'
                'Technologies: Flutter, Riverpod, FastAPI, PostgreSQL\n'
                'AI: Google Gemini for coaching & insights\n\n'
                'Special thanks to all contributors and the open-source community.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.6),
              ),
            ],
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _helplineRow(BuildContext context, String name, String number, String note) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text(note, style: const TextStyle(fontSize: 11, color: AppColors.textTertiaryDark)),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: number));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Helpline number copied: $number')),
            );
          },
          icon: const Icon(Icons.call, size: 14),
          label: Text(number, style: const TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.mintGreen,
            side: const BorderSide(color: AppColors.mintGreen),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
          ),
        ),
      ],
    );
  }

  Widget _resourceLink(BuildContext context, String name, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: url));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Copied link: $url')),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            const Icon(Icons.copy, size: 14, color: AppColors.teal),
            const SizedBox(width: 8),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 13, color: AppColors.teal, decoration: TextDecoration.underline))),
          ],
        ),
      ),
    );
  }
}
