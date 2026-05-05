import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../domain/entities/chat_entities.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/suggested_prompts.dart';

const _kGold = Color(0xFFD4B16A);

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
        title: Text(AppLocalizations.of(context).aiChatTitle),
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

          // Usage strip + paywall card pinned just above the input.
          _UsageStrip(),

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
            child: Consumer(
              builder: (context, innerRef, _) {
                final usage = innerRef.watch(chatUsageProvider).asData?.value;
                final atLimit = usage?.atLimit ?? false;
                final disabled = chatState.isSending || atLimit;
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !atLimit,
                        decoration: InputDecoration(
                          hintText: atLimit
                              ? AppLocalizations.of(context)
                                  .aiChatLimitReachedHint
                              : AppLocalizations.of(context).aiChatInputHint,
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
                        onSubmitted: disabled ? null : _sendMessage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: disabled
                          ? null
                          : () => _sendMessage(_controller.text),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: disabled
                              ? null
                              : CosmicColors.primaryGradient,
                          color: disabled ? CosmicColors.surfaceLight : null,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          atLimit
                              ? Icons.lock_outline_rounded
                              : Icons.arrow_upward,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Above-input strip that shows daily usage ("3 of 5 messages today")
/// for free users, a "Premium · Unlimited" badge for paying users, and
/// a tappable paywall card after a 429 lands.
class _UsageStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(chatInputProvider);
    final usageAsync = ref.watch(chatUsageProvider);

    final usage = usageAsync.asData?.value;
    if (usage == null) return const SizedBox.shrink();

    if (input.limitReached) {
      return _PaywallCard(
        onTap: () {
          ref.read(chatInputProvider.notifier).clearLimitReached();
          context.push('/paywall');
        },
      );
    }
    if (usage.isPremium) {
      return const _PremiumBadge();
    }
    return _CounterPill(used: usage.used, limit: usage.limit);
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.used, required this.limit});
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final atLimit = used >= limit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: atLimit
                  ? _kGold.withValues(alpha: 0.14)
                  : CosmicColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: atLimit ? _kGold : CosmicColors.glassBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  atLimit
                      ? Icons.lock_outline_rounded
                      : Icons.bolt_rounded,
                  size: 14,
                  color: atLimit ? _kGold : CosmicColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  atLimit
                      ? AppLocalizations.of(context).aiChatLimitReached
                      : AppLocalizations.of(context)
                          .aiChatMessagesToday(used, limit),
                  style: CosmicTypography.caption.copyWith(
                    color: atLimit ? _kGold : CosmicColors.textSecondary,
                    fontWeight: FontWeight.w600,
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

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGold),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 14,
                  color: _kGold,
                ),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).aiChatPremiumUnlimited,
                  style: const TextStyle(
                    color: _kGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
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

class _PaywallCard extends StatelessWidget {
  const _PaywallCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kGold),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: _kGold,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).aiChatPaywallTitle,
                        style: CosmicTypography.bodySmall.copyWith(
                          color: CosmicColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).aiChatPaywallSubtitle,
                        style: CosmicTypography.caption.copyWith(
                          color: CosmicColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _kGold,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
