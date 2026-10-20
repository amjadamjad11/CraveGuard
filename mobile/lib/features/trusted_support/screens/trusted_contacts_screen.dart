import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../services/demo_service.dart';

class TrustedContactsScreen extends ConsumerStatefulWidget {
  const TrustedContactsScreen({super.key});
  @override
  ConsumerState<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends ConsumerState<TrustedContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(demoModeProvider) && ref.read(trustedContactsProvider).isEmpty) {
        ref.read(trustedContactsProvider.notifier).state = DemoService().trustedContacts;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(trustedContactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trusted Support')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        backgroundColor: AppColors.teal,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: const Column(
              children: [
                Icon(Icons.privacy_tip, color: AppColors.teal, size: 28),
                SizedBox(height: 8),
                Text('Privacy First', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Messages are only sent when YOU choose to reach out. No one is contacted automatically.',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (contacts.isEmpty) _emptyState()
          else ...contacts.map((c) => _contactCard(c)),
        ],
      ),
    );
  }

  Widget _contactCard(Map<String, dynamic> c) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.amber.withValues(alpha: 0.2),
              child: Text((c['contact_name'] ?? 'X')[0].toUpperCase(), style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['contact_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('${c['contact_method'] ?? ''} • ${c['support_type'] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
              ],
            )),
            Switch(value: c['is_active'] ?? true, onChanged: (v) {
              final updated = List<Map<String, dynamic>>.from(ref.read(trustedContactsProvider));
              final idx = updated.indexWhere((x) => x['id'] == c['id']);
              if (idx >= 0) updated[idx] = {...updated[idx], 'is_active': v};
              ref.read(trustedContactsProvider.notifier).state = updated;
            }),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _sendSupport(c),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Ask for Support'),
          ),
        ),
      ],
    ),
  );

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)),
    child: const Column(
      children: [
        Icon(Icons.people_outline, size: 48, color: AppColors.textTertiaryDark),
        SizedBox(height: 12),
        Text('No trusted contacts yet', style: TextStyle(color: AppColors.textSecondaryDark)),
        SizedBox(height: 4),
        Text('Add someone you trust who can support you during difficult moments.',
          style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 12), textAlign: TextAlign.center),
      ],
    ),
  );

  void _sendSupport(Map<String, dynamic> c) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Reach out to ${c['contact_name']}?'),
      content: Text('Message preview:\n\n"${c['message_template'] ?? "I could use some encouragement."}"'
          '\n\nNote: Actual messaging requires a configured provider. This is a preview.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Support request recorded. (Preview — messaging provider not configured)')));
        }, child: const Text('Send')),
      ],
    ));
  }

  void _addContact() {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Trusted Contact', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: valueCtrl, decoration: const InputDecoration(labelText: 'Phone or email', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final contacts = List<Map<String, dynamic>>.from(ref.read(trustedContactsProvider));
                  contacts.add({
                    'id': contacts.length + 10, 'contact_name': nameCtrl.text,
                    'contact_method': 'sms', 'contact_value': valueCtrl.text,
                    'support_type': 'encouragement', 'is_active': true,
                    'message_template': "I'm having a difficult moment and could use some encouragement.",
                  });
                  ref.read(trustedContactsProvider.notifier).state = contacts;
                  Navigator.pop(context);
                }
              }, child: const Text('Add Contact')),
            ),
          ],
        ),
      ),
    );
  }
}
