import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';

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

  // Emoji + label pairs feel more intentional than raw emojis.
  static const _moods = [
    _Mood('😊', 'Glad'),
    _Mood('😌', 'Calm'),
    _Mood('🥰', 'Loved'),
    _Mood('✨', 'Sparkly'),
    _Mood('🤔', 'Curious'),
    _Mood('😴', 'Tired'),
    _Mood('😔', 'Heavy'),
    _Mood('😤', 'Restless'),
  ];

  static const _prompts = [
    'What surprised you today?',
    'Where did you feel most yourself?',
    'What are you releasing?',
    'What did the sky feel like today?',
  ];

  bool get _isEditing => widget.entryId != null;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

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

      if (mounted) context.pop();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dateLabel = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final canSave = _contentController.text.trim().isNotEmpty;

    return Scaffold(
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
                foregroundColor: Colors.white,
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
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
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
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 90, 20, 32),
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
                  _isEditing ? 'Edit your moment' : 'A new moment',
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
                  'HOW DOES TODAY FEEL?',
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
                  children: _moods.map((m) {
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
                                style: const TextStyle(fontSize: 18)),
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
                    'OR START FROM A PROMPT',
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
                    children: _prompts.map((prompt) {
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
                              Text(
                                prompt,
                                style: TextStyle(
                                  color: p.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 15,
                      height: 1.55,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Write what you noticed, felt, or wondered about today...',
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
    );
  }
}

class _Mood {
  const _Mood(this.emoji, this.label);
  final String emoji;
  final String label;
}
