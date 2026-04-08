import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/cosmic_button.dart';

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

  static const _moods = ['😊', '😌', '😔', '😤', '🥰', '😴', '🤔', '✨'];

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'New Entry'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How are you feeling?', style: CosmicTypography.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CosmicColors.primary.withOpacity(0.2)
                          : CosmicColors.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? CosmicColors.primary
                            : CosmicColors.glassBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(mood, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 10,
              textCapitalization: TextCapitalization.sentences,
              style: CosmicTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Write about your day, feelings, or cosmic insights...',
                hintStyle: CosmicTypography.bodyLarge.copyWith(
                  color: CosmicColors.textTertiary,
                ),
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
