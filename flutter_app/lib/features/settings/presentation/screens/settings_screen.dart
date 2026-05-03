import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../shared/providers/subscription_state_provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Subscription
          _SectionHeader('Subscription'),
          ListTile(
            leading: Icon(
              Icons.auto_awesome,
              color: isPremium ? CosmicColors.gold : CosmicColors.textSecondary,
            ),
            title: Text(isPremium ? 'Premium Active' : 'Free Plan'),
            subtitle: Text(
              isPremium
                  ? 'Manage your subscription'
                  : 'Upgrade for full access',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/paywall'),
          ),

          const Divider(),
          _SectionHeader('Appearance'),
          const _ThemeModeSwitcher(),

          const Divider(),
          _SectionHeader('Preferences'),

          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to notification preferences
            },
          ),

          const Divider(),
          _SectionHeader('Support'),

          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () {
              launchUrl(
                Uri.parse('mailto:support@livelyapp.co'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Rate the App'),
            onTap: () {
              // Open app store rating
            },
          ),

          const Divider(),
          _SectionHeader('Legal'),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              launchUrl(
                Uri.parse('https://livelyapp.co/privacy'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () {
              launchUrl(
                Uri.parse('https://livelyapp.co/terms'),
              );
            },
          ),

          const Divider(),
          _SectionHeader('Account'),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
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
          ListTile(
            leading: const Icon(Icons.delete_outline, color: CosmicColors.error),
            title: Text(
              'Delete Account',
              style: TextStyle(color: CosmicColors.error),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'This will permanently delete your account and all data. '
                    'This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: CosmicColors.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(authRepositoryProvider).deleteAccount();
                ref.read(currentUserProvider.notifier).clear();
                if (context.mounted) context.go('/auth');
              }
            },
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Lively v1.0.0',
              style: CosmicTypography.caption,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: CosmicTypography.overline,
      ),
    );
  }
}

/// Three-option segmented switcher for ThemeMode (system / light / dark)
/// that updates the persisted Riverpod themeModeProvider.
class _ThemeModeSwitcher extends ConsumerWidget {
  const _ThemeModeSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    Widget option(ThemeMode value, IconData icon, String label) {
      final selected = mode == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => notifier.set(value),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            option(ThemeMode.system, Icons.brightness_auto, 'System'),
            option(ThemeMode.light, Icons.light_mode_outlined, 'Light'),
            option(ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
          ],
        ),
      ),
    );
  }
}
