import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/features/ai_chat/domain/entities/chat_entities.dart';
import 'package:cosmic_mirror/features/ai_chat/presentation/providers/chat_provider.dart';
import 'package:cosmic_mirror/features/ai_chat/presentation/widgets/message_bubble.dart';
import 'package:cosmic_mirror/features/ai_chat/presentation/widgets/suggested_prompts.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Modernized conversation screen.
///
/// - Custom header with the AI avatar + name + "powered by your chart"
///   status line.
/// - Palette-aware so it themes correctly in both dark and iOS-light.
/// - Empty state: hero with the Lively logo + localized blurb +
///   tappable suggested prompts.
/// - Input bar: rounded glass pill, gold-gradient send button, lock
///   icon swap when the free daily cap is reached.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({this.threadId, super.key});

  /// The conversation id. **Null** = fresh chat — the thread is
  /// only created on the backend after the user sends their first
  /// message, so empty conversations never end up in the threads list.
  final String? threadId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  List<ChatMessage> _localMessages = [];

  /// Live thread id. Starts as widget.threadId (possibly null) and is
  /// filled in lazily after the first successful send creates one.
  String? _threadId;

  /// Re-entrancy guard. `chatState.isSending` only flips once the send
  /// reaches the network, but a fresh chat first awaits createThread() —
  /// a rapid double-tap in that window would otherwise create two
  /// threads / send twice.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _threadId = widget.threadId;
    // Rebuild on every keystroke so the send button enable-state
    // (and its color) reflect the current text.
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() => setState(() {});

  /// When the keyboard opens the list viewport shrinks — keep the latest
  /// message in view once the keyboard animation has settled.
  void _onFocusChanged() {
    if (!_focusNode.hasFocus) return;
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _scrollController.dispose();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  /// The message list is reversed (newest at offset 0), so "bottom" is
  /// offset 0 — exact even before lazily-built items have been measured.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage(String content) async {
    final text = content.trim();
    if (text.isEmpty || _isSubmitting) return;
    final notifier = ref.read(chatInputProvider.notifier);
    _isSubmitting = true;
    try {
      // For a fresh chat we lazily create the thread on the backend
      // *only* when the user actually sends — empty conversations never
      // pollute the threads list.
      var threadId = _threadId;
      if (threadId == null) {
        final newId = await notifier.createThread();
        // On failure the error is surfaced via state.error and the text
        // is still in the input, so the user can simply retry.
        if (newId == null || !mounted) return;
        threadId = newId;
        setState(() => _threadId = newId);
        // Refresh the threads list so the new conversation shows up.
        ref.invalidate(chatThreadsProvider);
      }

      final userMessage = ChatMessage(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        threadId: threadId,
        role: MessageRole.user,
        content: text,
        createdAt: DateTime.now(),
      );

      setState(() => _localMessages = [..._localMessages, userMessage]);
      _controller.clear();
      _scrollToBottom();

      final response = await notifier.sendMessage(threadId, text);
      if (!mounted) return;

      if (response == null) {
        // Send failed (offline, server error, daily cap). Take the
        // optimistic bubble back out and return the text to the input so
        // nothing the user typed is lost — the error strip offers a retry.
        setState(() {
          _localMessages =
              _localMessages.where((m) => m.id != userMessage.id).toList();
        });
        if (_controller.text.trim().isEmpty) {
          _controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
        return;
      }

      // Show the reply right away, then reconcile with the server copy
      // (which now holds both the prompt and the reply) before dropping
      // the local copies — clearing first made the user's own message
      // vanish until the refetch landed.
      setState(() => _localMessages = [..._localMessages, response]);
      _scrollToBottom();
      try {
        ref.invalidate(chatMessagesProvider(threadId));
        await ref.read(chatMessagesProvider(threadId).future);
      } catch (_) {
        // The provider now holds the error; its ErrorView offers a retry.
      }
      if (!mounted) return;
      setState(() => _localMessages = const []);
      _scrollToBottom();
    } finally {
      _isSubmitting = false;
    }
  }

  void _retryLastSend() {
    ref.read(chatInputProvider.notifier).clearError();
    _sendMessage(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chatState = ref.watch(chatInputProvider);
    // For a fresh chat (no thread yet) we don't hit the backend for
    // messages — we just show the empty state with local messages
    // (which will become non-empty after the first send).
    final threadId = _threadId;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _ChatHeader(),
            Expanded(
              child: threadId == null
                  ? _buildBody(<ChatMessage>[], chatState)
                  : ref.watch(chatMessagesProvider(threadId)).when(
                        // A freshly created thread starts loading right
                        // after the first send — keep showing the
                        // optimistic bubble + typing indicator instead of
                        // swapping the conversation for a shimmer.
                        loading: () => _localMessages.isNotEmpty
                            ? _buildBody(const <ChatMessage>[], chatState)
                            : const ShimmerList(),
                        error: (e, _) => ErrorView(
                          error: e,
                          onRetry: () => ref.invalidate(
                            chatMessagesProvider(threadId),
                          ),
                        ),
                        data: (serverMessages) =>
                            _buildBody(serverMessages, chatState),
                      ),
            ),
            // The daily-cap 429 is rendered by the paywall card instead.
            if (chatState.error != null && !chatState.limitReached)
              _ErrorStrip(
                message: FriendlyError.from(context, chatState.error).body,
                onRetry: _controller.text.trim().isNotEmpty &&
                        !chatState.isSending &&
                        FriendlyError.from(context, chatState.error).retryable
                    ? _retryLastSend
                    : null,
                onDismiss: () =>
                    ref.read(chatInputProvider.notifier).clearError(),
              ),
            const _UsageStrip(),
            _InputBar(
              controller: _controller,
              focusNode: _focusNode,
              isSending: chatState.isSending,
              onSubmit: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  /// Renders the message list (or empty state) for both branches —
  /// fresh chat with no server messages AND established thread with
  /// the fetched server messages. Keeps the build method readable.
  Widget _buildBody(
    List<ChatMessage> serverMessages,
    ChatInputState chatState,
  ) {
    final all = [...serverMessages, ..._localMessages];
    if (all.isEmpty) return _EmptyState(onPrompt: _sendMessage);
    final typing = chatState.isSending ? 1 : 0;
    // Reversed so the newest message sits at offset 0: the thread opens
    // at the latest message and stays pinned there when the keyboard
    // opens or a reply arrives.
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: all.length + typing,
      itemBuilder: (context, i) {
        if (i < typing) return const TypingIndicator();
        return MessageBubble(message: all[all.length - 1 - (i - typing)]);
      },
    );
  }
}

// ============================================================================
// Header
// ============================================================================

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 10),
      decoration: BoxDecoration(
        color: p.background,
        border: Border(bottom: BorderSide(color: p.glassBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: p.textPrimary),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            // A deep link / notification can open a chat with nothing
            // underneath it — fall back to the threads list.
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/chat'),
          ),
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: p.gold.withValues(alpha: 0.7),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: p.gold.withValues(alpha: 0.25),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/lively_logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.aiChatAstrologer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: p.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: p.success.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.aiChatStatusOnline,
                      style: TextStyle(
                        color: p.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Empty state
// ============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPrompt});
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    p.gold.withValues(alpha: 0.35),
                    p.gold.withValues(alpha: 0),
                  ],
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/lively_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l.aiChatEmptyHeadline,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.aiChatEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          SuggestedPrompts(onPromptSelected: onPrompt),
        ],
      ),
    );
  }
}

// ============================================================================
// Usage strip (counter / premium badge / paywall card)
// ============================================================================

class _UsageStrip extends ConsumerWidget {
  const _UsageStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(chatInputProvider);
    final usageAsync = ref.watch(chatUsageProvider);
    final usage = usageAsync.asData?.value;
    if (usage == null) return const SizedBox.shrink();

    // After the paywall closes, re-read usage so a fresh purchase
    // unlocks the input without leaving the screen.
    Future<void> openPaywall() async {
      await context.push('/paywall');
      if (context.mounted) ref.invalidate(chatUsageProvider);
    }

    if (input.limitReached) {
      return _PaywallCard(
        onTap: () {
          ref.read(chatInputProvider.notifier).clearLimitReached();
          openPaywall();
        },
      );
    }
    if (usage.isPremium) return const _PremiumBadge();
    return _CounterPill(
      used: usage.used,
      limit: usage.limit,
      // At the cap the input is locked — give the user a way forward.
      onTap: usage.atLimit ? openPaywall : null,
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.used, required this.limit, this.onTap});
  final int used;
  final int limit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final atLimit = used >= limit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: atLimit ? p.primary.withValues(alpha: 0.14) : p.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: atLimit ? p.primary : p.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  atLimit ? Icons.lock_outline_rounded : Icons.bolt_rounded,
                  size: 14,
                  color: atLimit ? p.primary : p.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    atLimit
                        ? l.aiChatLimitReached
                        : l.aiChatMessagesToday(used, limit),
                    style: TextStyle(
                      color: atLimit ? p.primary : p.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: p.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: p.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 14,
                color: p.primary,
              ),
              const SizedBox(width: 6),
              Text(
                l.aiChatPremiumUnlimited,
                style: TextStyle(
                  color: p.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaywallCard extends StatelessWidget {
  const _PaywallCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
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
              color: p.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.primary),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: p.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.aiChatPaywallTitle,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.aiChatPaywallSubtitle,
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: p.primary,
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

class _ErrorStrip extends StatelessWidget {
  const _ErrorStrip({
    required this.message,
    this.onRetry,
    this.onDismiss,
  });
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: p.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: p.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: p.error, fontSize: 12),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: p.error,
                minimumSize: const Size(44, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(AppLocalizations.of(context).errRetry),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: Icon(Icons.close_rounded, color: p.error, size: 16),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// Input bar
// ============================================================================

/// Mirrors the backend's maxChatMessageRunes.
const _maxMessageChars = 500;

class _InputBar extends ConsumerWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final usage = ref.watch(chatUsageProvider).asData?.value;
    final atLimit = usage?.atLimit ?? false;
    final hasText = controller.text.trim().isNotEmpty;
    final disabled = isSending || atLimit;
    final canSend = hasText && !disabled;

    return Container(
      // padding (not viewPadding): it drops to 0 while the keyboard is
      // up, so the bar doesn't float a home-indicator gap above it.
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: p.background,
        border: Border(top: BorderSide(color: p.glassBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: p.glassBorder),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                enabled: !atLimit,
                // Backend rejects messages over 500 characters; enforce
                // it here and show the counter only when it's close.
                maxLength: _maxMessageChars,
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) =>
                    currentLength < _maxMessageChars - 50
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '$currentLength/$_maxMessageChars',
                              style: TextStyle(
                                color: p.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 14.5,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText:
                      atLimit ? l.aiChatLimitReachedHint : l.aiChatInputHint,
                  hintStyle: TextStyle(color: p.textTertiary),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onSubmitted: canSend ? onSubmit : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(
            enabled: canSend,
            atLimit: atLimit,
            onTap: () => onSubmit(controller.text),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.atLimit,
    required this.onTap,
  });

  final bool enabled;
  final bool atLimit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      enabled: enabled,
      label: AppLocalizations.of(context).cmsChatSend,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    colors: [p.primaryHi, p.primary, p.primaryDim],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: enabled ? null : p.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled ? Colors.transparent : p.glassBorder,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: p.gold.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            atLimit ? Icons.lock_outline_rounded : Icons.arrow_upward_rounded,
            color: enabled ? p.onPrimary : p.textTertiary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
