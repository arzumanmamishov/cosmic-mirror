import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/api_url_override.dart';
import '../../../../config/env.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/locale_provider.dart';
import '../../../../shared/providers/subscription_state_provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Subscription
          _SectionHeader(l10n.settingsSubscription),
          ListTile(
            leading: Icon(
              Icons.auto_awesome,
              color: isPremium ? CosmicColors.gold : CosmicColors.textSecondary,
            ),
            title: Text(
              isPremium ? l10n.settingsPremiumActive : l10n.settingsFreePlan,
            ),
            subtitle: Text(
              isPremium
                  ? l10n.settingsManageSubscription
                  : l10n.settingsUpgrade,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/paywall'),
          ),

          const Divider(),
          _SectionHeader(l10n.settingsAppearance),
          const _ThemeModeSwitcher(),

          const Divider(),
          _SectionHeader(l10n.settingsLanguage),
          const _LanguagePicker(),

          const Divider(),
          _SectionHeader(l10n.settingsPreferences),

          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.profileNotifications),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to notification preferences
            },
          ),

          const Divider(),
          _SectionHeader(l10n.settingsSupport),

          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(l10n.profileHelp),
            onTap: () {
              launchUrl(
                Uri.parse('mailto:support@livelyapp.co'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: Text(l10n.settingsRateApp),
            onTap: () {
              // Open app store rating
            },
          ),

          const Divider(),
          _SectionHeader(l10n.settingsLegal),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.authPrivacy),
            onTap: () {
              launchUrl(
                Uri.parse('https://livelyapp.co/privacy'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.settingsTermsOfService),
            onTap: () {
              launchUrl(
                Uri.parse('https://livelyapp.co/terms'),
              );
            },
          ),

          if (Env.isDev) ...[
            const Divider(),
            const _SectionHeader('Developer'),
            const _ApiUrlOverrideTile(),
          ],

          const Divider(),
          _SectionHeader(l10n.settingsAccount),

          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.settingsSignOut),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) {
                  final dl10n = AppLocalizations.of(dialogCtx);
                  return AlertDialog(
                    title: Text(dl10n.settingsSignOut),
                    content: Text(dl10n.settingsSignOutConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: Text(dl10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: Text(dl10n.settingsSignOut),
                      ),
                    ],
                  );
                },
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
              l10n.settingsDeleteAccount,
              style: const TextStyle(color: CosmicColors.error),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) {
                  final dl10n = AppLocalizations.of(dialogCtx);
                  return AlertDialog(
                    title: Text(dl10n.settingsDeleteAccount),
                    content: Text(dl10n.settingsDeleteAccountConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: Text(dl10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: CosmicColors.error,
                        ),
                        child: Text(dl10n.settingsDelete),
                      ),
                    ],
                  );
                },
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
              l10n.settingsAppVersion,
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

/// English / Türkçe segmented language switcher backed by [localeProvider].
/// Picking a language persists it via SharedPreferences and applies
/// immediately. There is intentionally no "System" option — once the user
/// makes a choice we honor it across devices.
class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final notifier = ref.read(localeProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final activeCode =
        locale?.languageCode ?? Localizations.localeOf(context).languageCode;

    Widget option(String code, String label) {
      final selected = activeCode == code;
      return Expanded(
        child: GestureDetector(
          onTap: () => notifier.set(Locale(code)),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
            option('en', l10n.languageEnglish),
            option('tr', l10n.languageTurkish),
          ],
        ),
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
            option(
              ThemeMode.system,
              Icons.brightness_auto,
              AppLocalizations.of(context).settingsThemeSystem,
            ),
            option(
              ThemeMode.light,
              Icons.light_mode_outlined,
              AppLocalizations.of(context).settingsThemeLight,
            ),
            option(
              ThemeMode.dark,
              Icons.dark_mode_outlined,
              AppLocalizations.of(context).settingsThemeDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// Developer-only ListTile that shows the active API base URL and lets
/// the user override it at runtime when the dev machine's LAN IP
/// changes (so a stale binary can be redirected without a rebuild).
class _ApiUrlOverrideTile extends ConsumerWidget {
  const _ApiUrlOverrideTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = Env.apiBaseUrl;
    return ListTile(
      leading: const Icon(Icons.cloud_outlined),
      title: const Text('API base URL'),
      subtitle: Text(
        current,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CosmicTypography.caption,
      ),
      trailing: const Icon(Icons.edit_outlined, size: 18),
      onTap: () => _showEditDialog(context, ref, current),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(
      text: ApiUrlOverride.current ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Override API base URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Currently: $current', style: CosmicTypography.caption),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  hintText: 'http://192.168.0.75:8080',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Leave empty to fall back to the compile-time default. '
                'Changes take effect on the next API call.',
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await ApiUrlOverride.set(null);
                ref.invalidate(apiClientProvider);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiUrlOverride.set(controller.text);
                // Drop the cached Dio so the next request uses the
                // new base URL immediately.
                ref.invalidate(apiClientProvider);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }
}
