import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmic_mirror/shared/providers/subscription_state_provider.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_pulse.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 60,
              intensity: 0.7,
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 90, 20, 40),
            children: [
              FadeSlideIn(child: _ProfileHero(user: user)),
              const SizedBox(height: 24),
              if (user.sunSign != null)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: _BigThree(
                    sun: user.sunSign,
                    moon: user.moonSign,
                    rising: user.risingSign,
                  ),
                ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: const _StatsRow(),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: _SubscriptionCard(isPremium: isPremium),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 280),
                child: const _SectionTitle('Birth Data'),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                child: const _BirthDataCard(),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 360),
                child: const _SectionTitle('Account'),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 400),
                child: const _AccountLinks(),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 440),
                child: _SignOutButton(
                  onSignOut: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: p.surface,
                        title: const Text('Sign Out'),
                        content: const Text(
                          'You will need to sign in again to access your data.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: TextButton.styleFrom(
                              foregroundColor: p.error,
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(authRepositoryProvider).signOut();
                      ref.read(currentUserProvider.notifier).clear();
                      if (context.mounted) context.go('/auth');
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Lively · v1.0.0',
                  style: TextStyle(color: p.textTertiary, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =================== Hero ===================

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});
  final UserState user;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initial = (user.name?.isNotEmpty ?? false)
        ? user.name![0].toUpperCase()
        : '✦';

    return Column(
      children: [
        // Pulsing avatar with gradient ring
        CosmicPulse(
          color: p.primary,
          maxRadius: 70,
          duration: const Duration(seconds: 4),
          child: Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: p.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: p.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.name ?? 'Stargazer',
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email ?? '—',
          style: TextStyle(color: p.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

// =================== Big three ===================

class _BigThree extends StatelessWidget {
  const _BigThree({this.sun, this.moon, this.rising});
  final String? sun;
  final String? moon;
  final String? rising;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SignTile(
              label: 'Sun',
              sign: sun ?? '—',
              glyph: '☉',
              color: p.gold,
            ),
          ),
          _Divider(p: p),
          Expanded(
            child: _SignTile(
              label: 'Moon',
              sign: moon ?? '—',
              glyph: '☽',
              color: p.accent,
            ),
          ),
          _Divider(p: p),
          Expanded(
            child: _SignTile(
              label: 'Rising',
              sign: rising ?? '—',
              glyph: '↑',
              color: p.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.p});
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: p.glassBorder,
    );
  }
}

class _SignTile extends StatelessWidget {
  const _SignTile({
    required this.label,
    required this.sign,
    required this.glyph,
    required this.color,
  });

  final String label;
  final String sign;
  final String glyph;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Text(glyph, style: TextStyle(color: color, fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: p.textTertiary,
            fontSize: 9,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sign,
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// =================== Stats ===================

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatPill(
            icon: Icons.local_fire_department_rounded,
            value: '12',
            label: 'Day streak',
            color: Color(0xFFF07C82),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            icon: Icons.book_rounded,
            value: '8',
            label: 'Journal entries',
            color: Color(0xFF5ED39A),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            icon: Icons.auto_awesome_rounded,
            value: '24',
            label: 'Insights saved',
            color: Color(0xFF7B61FF),
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: p.textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =================== Subscription ===================

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.isPremium});
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: () => context.push('/paywall'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isPremium ? p.premiumGradient : null,
          color: isPremium ? null : p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPremium ? Colors.transparent : p.glassBorder,
          ),
          boxShadow: isPremium
              ? [
                  BoxShadow(
                    color: p.accent.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPremium
                    ? Colors.white.withValues(alpha: 0.2)
                    : p.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.workspace_premium_rounded,
                color: isPremium ? Colors.white : p.gold,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? 'Premium · Active' : 'Free Plan',
                    style: TextStyle(
                      color: isPremium ? Colors.white : p.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPremium
                        ? 'Unlimited insights · priority booking'
                        : 'Upgrade for full access to your chart',
                    style: TextStyle(
                      color: isPremium
                          ? Colors.white.withValues(alpha: 0.8)
                          : p.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isPremium
                  ? Colors.white.withValues(alpha: 0.8)
                  : p.textTertiary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// =================== Section title ===================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: p.textTertiary,
          fontSize: 11,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// =================== Birth data ===================

class _BirthDataCard extends ConsumerWidget {
  const _BirthDataCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.glassBorder),
      ),
      child: Column(
        children: [
          _BirthRow(
            icon: Icons.cake_rounded,
            label: 'Birth date',
            value: '—',
            color: p.accent,
          ),
          _RowDivider(p: p),
          _BirthRow(
            icon: Icons.access_time_rounded,
            label: 'Birth time',
            value: '—',
            color: p.gold,
          ),
          _RowDivider(p: p),
          _BirthRow(
            icon: Icons.place_rounded,
            label: 'Birthplace',
            value: '—',
            color: p.primary,
          ),
          _RowDivider(p: p),
          _ActionRow(
            icon: Icons.edit_rounded,
            label: 'Edit Birth Data',
            onTap: () => context.push('/onboarding'),
            primary: true,
          ),
        ],
      ),
    );
  }
}

class _BirthRow extends StatelessWidget {
  const _BirthRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: p.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 14,
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: primary ? p.primary : p.textSecondary, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: primary ? p.primary : p.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: p.textTertiary,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider({required this.p});
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: p.glassBorder,
    );
  }
}

// =================== Account links ===================

class _AccountLinks extends StatelessWidget {
  const _AccountLinks();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.glassBorder),
      ),
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.notifications_rounded,
            label: 'Notifications',
            onTap: () => context.push('/notifications'),
          ),
          _RowDivider(p: p),
          _ActionRow(
            icon: Icons.shield_rounded,
            label: 'Privacy',
            onTap: () => context.push('/legal/privacy'),
          ),
          _RowDivider(p: p),
          _ActionRow(
            icon: Icons.help_rounded,
            label: 'Help & Support',
            onTap: () => context.push('/support'),
          ),
          _RowDivider(p: p),
          _ActionRow(
            icon: Icons.tune_rounded,
            label: 'Settings',
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

// =================== Sign out ===================

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onSignOut,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: p.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: p.error, size: 18),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                color: p.error,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
