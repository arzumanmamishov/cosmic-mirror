import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/life_timeline/data/life_timeline_data.dart';

/// Bottom sheet for adding a new life-timeline moment. Returns a [LifeEvent]
/// when saved, or null if dismissed.
class AddEventSheet extends StatefulWidget {
  const AddEventSheet({super.key});

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  LifeEventCategory _category = LifeEventCategory.reflection;
  String? _mood;

  static const _moods = [
    'Elated', 'Grounded', 'Open', 'Pressured',
    'Free', 'Cleansed', 'Tender', 'Resolved',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      LifeEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        date: _date,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        mood: _mood,
        // Mock transits — in production, these come from Swiss Ephemeris
        transits: const [
          'Transit calculation pending',
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: p.glassBorder)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add a Moment',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A turning point worth remembering.',
                  style: TextStyle(color: p.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Title
                _Label(label: 'Title'),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleCtrl,
                  style: TextStyle(color: p.textPrimary, fontSize: 15),
                  decoration: _inputDecoration(p, 'e.g. Got the offer'),
                ),
                const SizedBox(height: 16),

                // Date
                _Label(label: 'When'),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: p.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: p.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(_date),
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category
                _Label(label: 'Category'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LifeEventCategory.values.map((c) {
                    final selected = c == _category;
                    return GestureDetector(
                      onTap: () => setState(() => _category = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? c.color.withValues(alpha: 0.18)
                              : p.surfaceElevated,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: selected
                                ? c.color
                                : p.glassBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              c.icon,
                              size: 14,
                              color: selected ? c.color : p.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c.label,
                              style: TextStyle(
                                color: selected ? c.color : p.textSecondary,
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
                const SizedBox(height: 16),

                // Mood
                _Label(label: 'How did it feel?', optional: true),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _moods.map((m) {
                    final selected = m == _mood;
                    return GestureDetector(
                      onTap: () => setState(
                        () => _mood = selected ? null : m,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? p.primary.withValues(alpha: 0.18)
                              : p.surfaceElevated,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: selected ? p.primary : p.glassBorder,
                          ),
                        ),
                        child: Text(
                          m,
                          style: TextStyle(
                            color: selected ? p.primary : p.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Description
                _Label(label: 'Notes', optional: true),
                const SizedBox(height: 6),
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  minLines: 3,
                  style: TextStyle(color: p.textPrimary, fontSize: 14),
                  decoration: _inputDecoration(
                    p,
                    'What was happening, what shifted...',
                  ),
                ),
                const SizedBox(height: 24),

                // Save
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save Moment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(AppPalette p, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: p.textTertiary),
      filled: true,
      fillColor: p.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.primary),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label, this.optional = false});
  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Text(
            '(optional)',
            style: TextStyle(
              color: p.textTertiary,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
