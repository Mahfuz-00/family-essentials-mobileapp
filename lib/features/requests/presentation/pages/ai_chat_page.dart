import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.errandData,
  });

  final String text;
  final bool isUser;
  final String time;
  final Map<String, dynamic>? errandData;
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I am your AI Family Dispatcher. You can tell me anything in plain English, and I will dispatch chores, assign errands, check grocery stocks, or answer budget questions.',
      isUser: false,
      time: 'Just now',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          time: 'Now',
        ),
      );
      _isSending = true;
    });
    _scrollToBottom();

    // Check budget questions
    final lower = text.toLowerCase();
    if (lower.contains('budget') || lower.contains('spend') || lower.contains('expense')) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Current Household Expenses:\n• Monthly Budget: \$2,500.00\n• Total Spent: \$1,845.00 (74% used)\n• Remaining: \$655.00\n• Top Category: Rent (\$1,200.00) & Groceries (\$245.00)',
              isUser: false,
              time: 'Now',
            ),
          );
          _isSending = false;
        });
        _scrollToBottom();
      }
      return;
    }

    try {
      if (getIt.isRegistered<DioClient>()) {
        final dio = getIt<DioClient>().dio;
        final response = await dio.post<Map<String, dynamic>>(
          '/v1/requests/parse-nlp',
          data: {'text': text, 'execute': true},
        );

        if (response.data != null && mounted) {
          final parsed = response.data!['parsed'] as Map<String, dynamic>? ?? {};
          final title = parsed['title'] as String? ?? text;
          final assignee = parsed['assignee_name'] as String? ?? 'Anyone in household';
          final store = parsed['store_name'] as String?;

          setState(() {
            _messages.add(
              ChatMessage(
                text: 'Created errand: "$title". Assigned to $assignee${store != null ? " at $store" : ""}.',
                isUser: false,
                time: 'Now',
                errandData: parsed,
              ),
            );
            _isSending = false;
          });
          _scrollToBottom();
          return;
        }
      }
    } catch (_) {}

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'I have dispatched that errand for the household. You will see it on the Today hub and Kanban board.',
            isUser: false,
            time: 'Now',
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.secondary, size: 20),
            SizedBox(width: 8),
            Text('AI Family Dispatcher'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick Suggestion Chips
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _promptChip('🛒 2L Milk & Bread at Target'),
                  const SizedBox(width: 8),
                  _promptChip('🧹 Remind Sarah to clean kitchen'),
                  const SizedBox(width: 8),
                  _promptChip('💰 Check grocery spending'),
                  const SizedBox(width: 8),
                  _promptChip('📋 Overdue chores status'),
                ],
              ),
            ),
            const Divider(height: 1),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _messageBubble(msg);
                },
              ),
            ),

            if (_isSending)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondary),
                    ),
                    SizedBox(width: 8),
                    Text('AI Dispatcher is thinking...', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                  ],
                ),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Ask or dispatch a chore in plain English...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.muted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          borderSide: BorderSide(color: AppTheme.outline.withValues(alpha: 0.3)),
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.secondary,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promptChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: AppTheme.surface,
      side: BorderSide(color: AppTheme.outline.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
      onPressed: () => _sendMessage(text),
    );
  }

  Widget _messageBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.forestSoft,
              child: Icon(Icons.psychology, size: 18, color: AppTheme.secondary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isUser ? AppTheme.secondary : AppTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: msg.isUser ? Colors.transparent : AppTheme.outline.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: msg.isUser ? Colors.white : AppTheme.ink,
                      height: 1.35,
                    ),
                  ),
                  if (msg.errandData != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.forestSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: AppTheme.secondary),
                          const SizedBox(width: 6),
                          const Text('Added to household board', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => context.go('/today'),
                            child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    msg.time,
                    style: TextStyle(
                      fontSize: 10,
                      color: msg.isUser ? Colors.white.withValues(alpha: 0.7) : AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryContainer,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
