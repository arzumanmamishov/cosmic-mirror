import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/journal/presentation/screens/journal_screen.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class JournalEntryScreen extends ConsumerStatefulWidget {
  const JournalEntryScreen({super.key, this.entryId});

  final String? entryId;

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  final _contentController = TextEditingController();
  String? _selectedMood;
  bool _isSaving = false;

  // Edit mode: the existing entry has to be loaded into the editor first —
  // previously the editor opened empty and saving overwrote the entry.
  bool _isLoadingEntry = false;
  bool _loadFailed = false;
  String _initialContent = '';
  String? _initialMood;

  /// The backend caps entries at 10,000 characters.
  static const _maxContentLength = 10000;

  // Emoji + label pairs feel more intentional than raw emojis. Labels are
  // localized at build time via [_moods] / [_prompts].
  List<_Mood> _moods(AppLocalizations l) => [
        _Mood('😊', l.journalMoodGlad),
        _Mood('😌', l.journalMoodCalm),
        _Mood('🥰', l.journalMoodLoved),
        _Mood('✨', l.journalMoodSparkly),
        _Mood('🤔', l.journalMoodCurious),
        _Mood('😴', l.journalMoodTired),
        _Mood('😔', l.journalMoodHeavy),
        _Mood('😤', l.journalMoodRestless),
      ];

  List<String> _prompts(AppLocalizations l) => [
        l.journalPrompt1,
        l.journalPrompt2,
        l.journalPrompt3,
        l.journalPrompt4,
      ];

  bool get _isEditing => widget.entryId != null;

  bool get _isDirty =>
      _contentController.text.trim() != _initialContent.trim() ||
      _selectedMood != _initialMood;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadEntry();
  }

  /// There's no single-entry GET endpoint, so pick the entry out of the
  /// (usually already cached) journal list.
  Future<void> _loadEntry() async {
    setState(() {
      _isLoadingEntry = true;
      _loadFailed = false;
    });
    try {
      final entries = await ref.read(journalEntriesProvider.future);
      final entry = entries.where((e) => '${e['id']}' == widget.entryId);
      if (!mounted) return;
      if (entry.isEmpty) {
        setState(() {
          _isLoadingEntry = false;
          _loadFailed = true;
        });
        return;
      }
      final e = entry.first;
      _initialContent = e['content'] as String? ?? '';
      _initialMood = e['mood'] as String?;
      _contentController.text = _initialContent;
      setState(() {
        _selectedMood = _initialMood;
        _isLoadingEntry = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingEntry = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _confirmDiscard() async {
    final l = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.oaphJournalDiscardTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.oaphJournalKeepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.oaphJournalDiscard),
          ),
        ],
      ),
    );
    if ((discard ?? false) && mounted) context.pop();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || _contentController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    // Captured up front: the user may leave while the request is in flight.
    final container = ProviderScope.containerOf(context, listen: false);

    try {
      final client = ref.read(apiClientProvider);
      final data = {
        'content': _contentController.text.trim(),
        'mood': _selectedMood,
        'entry_date': DateTime.now().toIso8601String().split('T').first,
      };

      if (_isEditing) {
        await client.put<dynamic>(
          ApiEndpoints.journalEntry(widget.entryId!),
          data: data,
        );
      } else {
        await client.post<dynamic>(ApiEndpoints.journal, data: data);
      }

      // Refresh the list so the new / edited entry shows up on return.
      container.invalidate(journalEntriesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).journalSaveFailed(
                FriendlyError.from(context, e).body,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final moods = _moods(l);
    final prompts = _prompts(l);
    final dateLabel = DateFormat(
      'EEEE, MMMM d',
      Localizations.localeOf(context).toString(),
    ).format(DateTime.now());
    final canSave = _contentController.text.trim().isNotEmpty &&
        !_isLoadingEntry &&
        !_loadFailed &&
        (!_isEditing || _isDirty);

    // Ask before throwing away unsaved writing on back / swipe.
    return PopScope(
      canPop: !_isDirty || _isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: (canSave && !_isSaving) ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: p.onPrimary,
                disabledBackgroundColor: p.surfaceElevated,
                disabledForegroundColor: p.textTertiary,
                minimumSize: const Size(72, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: p.onPrimary,
                      ),
                    )
                  : Text(l.journalSave),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 40,
              intensity: 0.5,
            ),
          ),
          if (_isLoadingEntry)
            Center(child: CircularProgressIndicator(color: p.primary))
          else if (_loadFailed)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.oaphJournalLoadFailed,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(journalEntriesProvider);
                        _loadEntry();
                      },
                      child: Text(l.errRetry),
                    ),
                  ],
                ),
              ),
            )
          else
          ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            // Clear the transparent app bar on any notch height.
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
              20,
              32,
            ),
            children: [
              FadeSlideIn(
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Text(
                  _isEditing ? l.journalEditMoment : l.journalNewMoment,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Mood
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: Text(
                  l.journalMoodHeader,
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: moods.map((m) {
                    final selected = _selectedMood == m.emoji;
                    return GestureDetector(
                      onTap: () => setState(
                        () => _selectedMood = selected ? null : m.emoji,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? p.primary.withValues(alpha: 0.18)
                              : p.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: selected ? p.primary : p.glassBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(m.emoji,
                                style: const TextStyle(fontSize: 18),),
                            const SizedBox(width: 6),
                            Text(
                              m.label,
                              style: TextStyle(
                                color: selected
                                    ? p.primary
                                    : p.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Prompts (clickable)
              if (_contentController.text.isEmpty) ...[
                FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: Text(
                    l.journalPromptHeader,
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 260),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: prompts.map((prompt) {
                      return GestureDetector(
                        onTap: () => setState(() {
                          _contentController.text = '$prompt\n\n';
                          _contentController.selection =
                              TextSelection.fromPosition(
                            TextPosition(
                              offset: _contentController.text.length,
                            ),
                          );
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: p.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 12,
                                color: p.primary,
                              ),
                              const SizedBox(width: 6),
                              // Flexible so a long (or Turkish / scaled)
                              // prompt wraps instead of overflowing.
                              Flexible(
                                child: Text(
                                  prompt,
                                  style: TextStyle(
                                    color: p.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Editor
              FadeSlideIn(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: p.glassBorder),
                  ),
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_maxContentLength),
                    ],
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 15,
                      height: 1.55,
                    ),
                    decoration: InputDecoration(
                      hintText: l.journalEditorHint,
                      hintStyle: TextStyle(
                        color: p.textTertiary,
                        fontSize: 15,
                        height: 1.55,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class _Mood {
  const _Mood(this.emoji, this.label);
  final String emoji;
  final String label;
}
