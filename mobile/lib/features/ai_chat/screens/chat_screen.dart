import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../core/constants.dart';
import '../../../providers/app_providers.dart';
import '../../../services/demo_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(chatMessagesProvider).isEmpty) {
        ref.read(chatMessagesProvider.notifier).state = DemoService().chatMessages;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(gradient: AppColors.mintGradient, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CraveCoach', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('Your support assistant', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () {
              ref.read(chatMessagesProvider.notifier).state = DemoService().chatMessages;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == messages.length && _isTyping) {
                  return _typingIndicator();
                }
                final msg = messages[i];
                final isUser = msg['role'] == 'user';
                return _chatBubble(msg['content'] ?? '', isUser);
              },
            ),
          ),
          // Suggested prompts
          if (messages.length <= 2)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: AppConstants.suggestedPrompts.take(5).map((p) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(p, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _send(p),
                    backgroundColor: AppColors.cardDark,
                    side: const BorderSide(color: AppColors.navyLight),
                  ),
                )).toList(),
              ),
            ),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            decoration: BoxDecoration(
              color: AppColors.deepNavy,
              border: Border(top: BorderSide(color: AppColors.navyLight.withValues(alpha: 0.5))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: 3, minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(null),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: AppColors.navyLight.withValues(alpha: 0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.mintGradient),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _send(null),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatBubble(String content, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(gradient: AppColors.mintGradient, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.teal : AppColors.cardDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(content, style: TextStyle(
                color: isUser ? Colors.white : AppColors.textPrimaryDark,
                fontSize: 14, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingIndicator() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(
        width: 28, height: 28, margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(gradient: AppColors.mintGradient, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
      ),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(18)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _dot(0), const SizedBox(width: 4),
          _dot(1), const SizedBox(width: 4),
          _dot(2),
        ]),
      ),
    ]),
  );

  Widget _dot(int index) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.3, end: 1.0),
    duration: Duration(milliseconds: 600 + index * 200),
    builder: (context, v, child) => Opacity(
      opacity: v,
      child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
    ),
  );

  void _send(String? text) async {
    final msg = text ?? _msgCtrl.text.trim();
    if (msg.isEmpty) return;
    _msgCtrl.clear();

    final messages = List<Map<String, dynamic>>.from(ref.read(chatMessagesProvider));
    messages.add({'id': messages.length + 1, 'role': 'user', 'content': msg, 'created_at': DateTime.now().toIso8601String()});
    ref.read(chatMessagesProvider.notifier).state = messages;

    setState(() => _isTyping = true);
    _scrollToBottom();

    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 1200));

    final response = DemoService().getFallbackChatResponse(msg);
    final updated = List<Map<String, dynamic>>.from(ref.read(chatMessagesProvider));
    updated.add({'id': updated.length + 1, 'role': 'assistant', 'content': response, 'created_at': DateTime.now().toIso8601String()});
    ref.read(chatMessagesProvider.notifier).state = updated;

    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }
}
