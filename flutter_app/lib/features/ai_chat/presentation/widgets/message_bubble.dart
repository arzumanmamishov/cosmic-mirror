import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/ai_chat/domain/entities/chat_entities.dart';
import 'package:flutter/material.dart';

/// Modern chat bubble.
///
///   - User messages: gold gradient pill aligned to the right.
///   - AI messages: glass card on the left with the Lively logo as the
///     avatar, soft rounded corners, no harsh borders.
///
/// Reads colors from the palette so it themes correctly in both the
/// dark cosmic and iOS-style light modes.
class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _Avatar(),
            const SizedBox(width: 10),
          ] else
            const SizedBox(width: 48),
          Flexible(
            child: _Bubble(content: message.content, isUser: isUser),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Subtle gold ring so the avatar reads as the brand mark,
        // not a generic profile circle.
        border: Border.all(color: p.gold.withValues(alpha: 0.7), width: 1.2),
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
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.content, required this.isUser});
  final String content;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
      bottomLeft: Radius.circular(isUser ? 22 : 6),
      bottomRight: Radius.circular(isUser ? 6 : 22),
    );

    if (isUser) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          // Brand gold gradient — replaces the previous muted
          // primary-tinted box for a way more polished user message.
          gradient: const LinearGradient(
            colors: [Color(0xFFE9D49A), Color(0xFFD4B16A), Color(0xFF9F7637)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: p.gold.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          content,
          style: const TextStyle(
            color: Color(0xFF1A1F2E),
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
      );
    }

    // AI message — glass card.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: radius,
        border: Border.all(color: p.glassBorder),
      ),
      child: Text(
        content,
        style: TextStyle(
          color: p.textPrimary,
          fontSize: 14.5,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Three-dot typing indicator with the same avatar + bubble shell as
/// an AI message. Reads from the palette so it themes correctly.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Avatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomRight: Radius.circular(22),
                bottomLeft: Radius.circular(6),
              ),
              border: Border.all(color: p.glassBorder),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.18;
                    final progress =
                        ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
                    final t = 1 - (progress * 2 - 1).abs();
                    final opacity = 0.25 + 0.75 * t;
                    return Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 5),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: p.gold.withValues(alpha: opacity),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
