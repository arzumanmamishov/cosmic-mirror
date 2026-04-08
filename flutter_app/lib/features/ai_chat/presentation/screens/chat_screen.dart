import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../domain/entities/chat_entities.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/suggested_prompts.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.threadId, super.key});

  final String threadId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  List<ChatMessage> _localMessages = [];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      threadId: widget.threadId,
      role: MessageRole.user,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    setState(() {
      _localMessages = [..._localMessages, userMessage];
    });
    _controller.clear();
    _scrollToBottom();

    final response = await ref
        .read(chatInputProvider.notifier)
        .sendMessage(widget.threadId, content.trim());

    if (response != null) {
      setState(() {
        _localMessages = [..._localMessages, response];
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.threadId));
    final chatState = ref.watch(chatInputProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Astrologer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Thread options: rename, delete
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const ShimmerList(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(
                  chatMessagesProvider(widget.threadId),
                ),
              ),
              data: (serverMessages) {
                final allMessages = [...serverMessages, ..._localMessages];

                if (allMessages.isEmpty) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: CosmicColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CosmicColors.primary.withOpacity(0.3),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Your Personal Astrologer',
                          style: CosmicTypography.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask me anything about your chart, transits,\nor daily cosmic guidance.',
                          style: CosmicTypography.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        SuggestedPrompts(onPromptSelected: _sendMessage),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: allMessages.length + (chatState.isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == allMessages.length && chatState.isSending) {
                      return const TypingIndicator();
                    }
                    return MessageBubble(message: allMessages[index]);
                  },
                );
              },
            ),
          ),

          // Error bar
          if (chatState.error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CosmicColors.error.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: CosmicColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.error!,
                      style: CosmicTypography.caption.copyWith(
                        color: CosmicColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).viewPadding.bottom,
            ),
            decoration: BoxDecoration(
              color: CosmicColors.surface,
              border: Border(
                top: BorderSide(color: CosmicColors.glassBorder),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ask your astrologer...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: CosmicColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: chatState.isSending
                      ? null
                      : () => _sendMessage(_controller.text),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: chatState.isSending
                          ? null
                          : CosmicColors.primaryGradient,
                      color: chatState.isSending
                          ? CosmicColors.surfaceLight
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
