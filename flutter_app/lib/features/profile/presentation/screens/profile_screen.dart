import 'package:cached_network_image/cached_network_image.dart';
import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmic_mirror/features/profile/presentation/providers/profile_providers.dart';
import 'package:cosmic_mirror/shared/providers/subscription_state_provider.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/utils/avatar_url.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_pulse.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final p = context.palette;

    // ProfileScreen is rendered both as a pushed route (/profile) AND as
    // the 5th bottom-nav tab inside HomeScreen. As a tab there is nothing
    // to pop, so suppress the back arrow.
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: canPop ? const BackButton() : null,
        automaticallyImplyLeading: canPop,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppLocalizations.of(context).profileEditProfile,
            onPressed: () => _showEditProfileSheet(context, ref),
          ),
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
                child: _SectionTitle(
                  AppLocalizations.of(context).profileBirthData,
                ),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                child: const _BirthDataCard(),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 360),
                child: _SectionTitle(
                  AppLocalizations.of(context).profileAccount,
                ),
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
                      builder: (c) {
                        final l10n = AppLocalizations.of(c);
                        return AlertDialog(
                          backgroundColor: p.surface,
                          title: Text(l10n.profileSignOut),
                          content: Text(l10n.profileSignOutConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              style: TextButton.styleFrom(
                                foregroundColor: p.error,
                              ),
                              child: Text(l10n.profileSignOut),
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

// =================== Edit profile sheet ===================

Future<void> _showEditProfileSheet(BuildContext context, WidgetRef ref) async {
  final p = context.palette;
  final user = ref.read(currentUserProvider);
  final nameCtrl = TextEditingController(text: user.name ?? '');

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: _EditProfileForm(
          nameCtrl: nameCtrl,
          email: user.email,
          onSave: (newName) async {
            final apiClient = ref.read(apiClientProvider);
            try {
              await apiClient.put<dynamic>(
                ApiEndpoints.me,
                data: {'name': newName},
              );
              ref.read(currentUserProvider.notifier).updateName(newName);
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            } catch (e) {
              if (sheetContext.mounted) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(sheetContext)
                          .profileSaveError(e.toString()),
                    ),
                  ),
                );
              }
            }
          },
          onEditBirthData: () {
            Navigator.pop(sheetContext);
            context.push('/profile/edit-birth-data');
          },
        ),
      );
    },
  );
  nameCtrl.dispose();
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm({
    required this.nameCtrl,
    required this.email,
    required this.onSave,
    required this.onEditBirthData,
  });

  final TextEditingController nameCtrl;
  final String? email;
  final ValueChanged<String> onSave;
  final VoidCallback onEditBirthData;

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: p.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.profileEditProfile,
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.profileNameLabel,
          style: TextStyle(
            color: p.textTertiary,
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: p.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.glassBorder),
          ),
          child: TextField(
            controller: widget.nameCtrl,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: p.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: l10n.yourName,
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.profileEmailLabel,
          style: TextStyle(
            color: p.textTertiary,
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: p.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.glassBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.email ?? '—',
                  style: TextStyle(color: p.textSecondary, fontSize: 14),
                ),
              ),
              Icon(Icons.lock_outline, color: p.textTertiary, size: 14),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.profileEmailNote,
          style: TextStyle(color: p.textTertiary, fontSize: 11),
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: widget.onEditBirthData,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.glassBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.cake_rounded, color: p.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.profileEditBirthData,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: p.textTertiary,
                  size: 12,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    final newName = widget.nameCtrl.text.trim();
                    if (newName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.profileNameRequired)),
                      );
                      return;
                    }
                    setState(() => _saving = true);
                    widget.onSave(newName);
                    if (mounted) setState(() => _saving = false);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    l10n.profileSave,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// =================== Hero ===================

class _ProfileHero extends ConsumerWidget {
  const _ProfileHero({required this.user});
  final UserState user;

  Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
    final p = context.palette;
    final hasAvatar = user.avatarUrl != null;
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: p.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: p.primary),
                title: Text(l10n.avatarChooseFromGallery),
                onTap: () =>
                    Navigator.pop(sheetContext, _AvatarAction.gallery),
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_rounded, color: p.primary),
                title: Text(l10n.avatarTakePhoto),
                onTap: () => Navigator.pop(sheetContext, _AvatarAction.camera),
              ),
              if (hasAvatar)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: p.error),
                  title: Text(
                    l10n.avatarRemovePhoto,
                    style: TextStyle(color: p.error),
                  ),
                  onTap: () =>
                      Navigator.pop(sheetContext, _AvatarAction.remove),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action == null || !context.mounted) return;

    final notifier = ref.read(currentUserProvider.notifier);

    if (action == _AvatarAction.remove) {
      await notifier.clearAvatar();
      return;
    }

    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(
        source: action == _AvatarAction.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (file == null) return;
      final saved = await notifier.setAvatar(file.path);
      if (saved == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).avatarSaveError),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).avatarPickerError),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final initial = (user.name?.isNotEmpty ?? false)
        ? user.name![0].toUpperCase()
        : '✦';

    return Column(
      children: [
        // Pulsing avatar with gradient ring — tap to change photo.
        GestureDetector(
          onTap: () => _pickAvatar(context, ref),
          child: CosmicPulse(
            color: p.primary,
            maxRadius: 70,
            duration: const Duration(seconds: 4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
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
                  child: ClipOval(
                    child: () {
                      final url = resolveAvatarUrl(user.avatarUrl);
                      if (url == null) {
                        return _AvatarFallback(initial: initial);
                      }
                      return CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        width: 94,
                        height: 94,
                        placeholder: (_, __) =>
                            _AvatarFallback(initial: initial),
                        errorWidget: (_, __, ___) =>
                            _AvatarFallback(initial: initial),
                      );
                    }(),
                  ),
                ),
                // Small camera badge in the lower right.
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: p.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.background, width: 2),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.name ?? AppLocalizations.of(context).stargazer,
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

enum _AvatarAction { gallery, camera, remove }

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
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

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final stats = statsAsync.asData?.value;
    return Row(
      children: [
        Expanded(
          child: _StatPill(
            icon: Icons.local_fire_department_rounded,
            value: stats == null ? '—' : '${stats.streak}',
            label: AppLocalizations.of(context).profileDayStreak,
            color: const Color(0xFFF07C82),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            icon: Icons.book_rounded,
            value: stats == null ? '—' : '${stats.journalEntries}',
            label: AppLocalizations.of(context).profileJournalEntries,
            color: const Color(0xFF5ED39A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            icon: Icons.chat_bubble_outline_rounded,
            value: stats == null ? '—' : '${stats.aiChats}',
            label: AppLocalizations.of(context).profileAIChats,
            color: const Color(0xFF7B61FF),
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
                    isPremium
                        ? AppLocalizations.of(context).profileSubscriptionPremium
                        : AppLocalizations.of(context).profileSubscriptionFree,
                    style: TextStyle(
                      color: isPremium ? Colors.white : p.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPremium
                        ? AppLocalizations.of(context)
                            .profileSubscriptionPremiumDesc
                        : AppLocalizations.of(context)
                            .profileSubscriptionFreeDesc,
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
    final profileAsync = ref.watch(birthProfileProvider);
    final profile = profileAsync.asData?.value;

    String birthDate = '—';
    String birthTime = '—';
    String birthPlace = '—';
    if (profile != null) {
      final d = profile.birthDate;
      birthDate =
          '${_monthName(d.month)} ${d.day}, ${d.year}';
      birthPlace = profile.birthPlace.isNotEmpty ? profile.birthPlace : '—';
      if (profile.birthTimeKnown && profile.birthTime != null) {
        final t = profile.birthTime!;
        birthTime =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      } else {
        birthTime = AppLocalizations.of(context).profileBirthTimeUnknown;
      }
    }

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
            label: AppLocalizations.of(context).profileBirthDate,
            value: birthDate,
            color: p.accent,
          ),
          _RowDivider(p: p),
          _BirthRow(
            icon: Icons.access_time_rounded,
            label: AppLocalizations.of(context).profileBirthTime,
            value: birthTime,
            color: p.gold,
          ),
          _RowDivider(p: p),
          _BirthRow(
            icon: Icons.place_rounded,
            label: AppLocalizations.of(context).profileBirthPlace,
            value: birthPlace,
            color: p.primary,
          ),
          _RowDivider(p: p),
          _ActionRow(
            icon: Icons.edit_rounded,
            label: AppLocalizations.of(context).profileEditBirthData,
            onTap: () => context.push('/profile/edit-birth-data'),
            primary: true,
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[(m - 1).clamp(0, 11)];
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
            label: AppLocalizations.of(context).profileNotifications,
            onTap: () => context.push('/notifications'),
          ),
          _RowDivider(p: p),
          _ActionRow(
            icon: Icons.shield_rounded,
            label: AppLocalizations.of(context).profilePrivacy,
            onTap: () => context.push('/legal/privacy'),
          ),
          _RowDivider(p: p),
          _ActionRow(
            icon: Icons.help_rounded,
            label: AppLocalizations.of(context).profileHelp,
            onTap: () => context.push('/support'),
          ),
          _RowDivider(p: p),
          _ActionRow(
            icon: Icons.tune_rounded,
            label: AppLocalizations.of(context).profileSettings,
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
              AppLocalizations.of(context).profileSignOut,
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
