import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../services/demo_service.dart';

class MotivationVaultScreen extends ConsumerStatefulWidget {
  const MotivationVaultScreen({super.key});
  @override
  ConsumerState<MotivationVaultScreen> createState() => _MotivationVaultScreenState();
}

class _MotivationVaultScreenState extends ConsumerState<MotivationVaultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(demoModeProvider) && ref.read(motivationalMediaProvider).isEmpty) {
        ref.read(motivationalMediaProvider.notifier).state = DemoService().motivationalMedia;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(motivationalMediaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Motivation Vault')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: AppColors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.lavender.withValues(alpha: 0.2), AppColors.teal.withValues(alpha: 0.1)]),
              borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                const Icon(Icons.favorite, size: 36, color: AppColors.lavender),
                const SizedBox(height: 12),
                Text('Your Personal Motivation', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text('Save photos, messages, and reasons that keep you going.',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty) _emptyState()
          else ...items.map((item) => _mediaCard(item)),
        ],
      ),
    );
  }

  Widget _mediaCard(Map<String, dynamic> item) => Container(
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
              decoration: BoxDecoration(color: AppColors.lavender.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(
                item['media_type'] == 'photo' ? Icons.photo : item['media_type'] == 'voice' ? Icons.mic : Icons.format_quote,
                color: AppColors.lavender, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(item['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.w500))),
            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textTertiaryDark), onPressed: () {
              final updated = List<Map<String, dynamic>>.from(ref.read(motivationalMediaProvider));
              updated.removeWhere((m) => m['id'] == item['id']);
              ref.read(motivationalMediaProvider.notifier).state = updated;
            }),
          ],
        ),
        if (item['content_text'] != null) ...[
          const SizedBox(height: 12),
          Text(item['content_text'], style: const TextStyle(color: AppColors.textSecondaryDark, height: 1.5, fontStyle: FontStyle.italic)),
        ],
      ],
    ),
  );

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)),
    child: const Column(
      children: [
        Icon(Icons.photo_library_outlined, size: 48, color: AppColors.textTertiaryDark),
        SizedBox(height: 12),
        Text('Your vault is empty', style: TextStyle(color: AppColors.textSecondaryDark)),
        SizedBox(height: 4),
        Text('Add photos, messages, or reasons that motivate you to stay strong.',
          style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 12), textAlign: TextAlign.center),
      ],
    ),
  );

  void _addItem() {
    final titleCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Motivation', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title))),
            const SizedBox(height: 12),
            TextField(controller: textCtrl, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Your message or reason', prefixIcon: Icon(Icons.format_quote))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  final items = List<Map<String, dynamic>>.from(ref.read(motivationalMediaProvider));
                  items.insert(0, {
                    'id': items.length + 10, 'media_type': 'text',
                    'title': titleCtrl.text, 'content_text': textCtrl.text,
                    'created_at': DateTime.now().toIso8601String(),
                  });
                  ref.read(motivationalMediaProvider.notifier).state = items;
                  Navigator.pop(context);
                }
              }, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
