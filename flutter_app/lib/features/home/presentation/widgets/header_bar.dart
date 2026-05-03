import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';

class HomeHeaderBar extends ConsumerWidget {
  const HomeHeaderBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Avatar with gradient ring
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: p.primaryGradient,
            ),
            child: CircleAvatar(
              backgroundColor: p.surfaceElevated,
              child: Text(
                _initial(user.name),
                style: TextStyle(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? 'Stargazer',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('✨', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          _IconButton(
            icon: Icons.forum_rounded,
            onTap: () => context.push('/chat'),
          ),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.notifications_rounded,
            onTap: () => context.push('/settings'),
            hasBadge: true,
          ),
        ],
      ),
    );
  }

  String _initial(String? name) {
    if (name == null || name.isEmpty) return '✨';
    return name.trim().substring(0, 1).toUpperCase();
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: p.glassBorder),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: p.textPrimary, size: 20),
          ),
          if (hasBadge)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: p.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.background, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
