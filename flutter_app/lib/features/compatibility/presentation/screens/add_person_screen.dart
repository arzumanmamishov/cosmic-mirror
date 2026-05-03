import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/widgets/birthplace_search.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';

class AddPersonScreen extends ConsumerStatefulWidget {
  const AddPersonScreen({super.key});

  @override
  ConsumerState<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends ConsumerState<AddPersonScreen> {
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  String? _birthPlace;
  double? _lat;
  double? _lng;
  String? _tz;
  String _relationship = 'Partner';
  bool _birthTimeKnown = false;
  TimeOfDay? _birthTime;
  bool _isLoading = false;
  String? _error;

  static const _relationships = [
    'Partner', 'Friend', 'Family', 'Coworker', 'Crush', 'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameController.text.trim().length >= 2 &&
      _birthDate != null &&
      _birthPlace != null;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1995, 6, 15),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _birthTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) setState(() => _birthTime = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      await client.post<dynamic>(
        ApiEndpoints.people,
        data: {
          'name': _nameController.text.trim(),
          'relationship': _relationship,
          'birth_date': _formatDate(_birthDate!),
          if (_birthTimeKnown && _birthTime != null)
            'birth_time': _formatTime(_birthTime!),
          'birth_time_known': _birthTimeKnown,
          'birth_place': _birthPlace,
          'latitude': _lat,
          'longitude': _lng,
          'timezone': _tz,
        },
      );
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 50,
              intensity: 0.6,
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 90, 20, 32),
            children: [
              FadeSlideIn(
                child: Text(
                  'Add Someone',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Text(
                  "We'll compare their chart with yours.",
                  style: TextStyle(color: p.textSecondary, fontSize: 13.5),
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: _SectionLabel(label: 'Their name'),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: p.textPrimary, fontSize: 15),
                  decoration: _decoration(p, 'e.g. Theo Marlow'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 20),

              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: _SectionLabel(label: 'Relationship'),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _relationships.map((r) {
                    final selected = r == _relationship;
                    return GestureDetector(
                      onTap: () => setState(() => _relationship = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
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
                          r,
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
              ),
              const SizedBox(height: 20),

              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: _SectionLabel(label: 'Birth date'),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: _PickerRow(
                  icon: Icons.calendar_month_rounded,
                  value: _birthDate == null
                      ? 'Select a date'
                      : DateFormat('EEEE, MMM d, yyyy').format(_birthDate!),
                  placeholder: _birthDate == null,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 20),

              FadeSlideIn(
                delay: const Duration(milliseconds: 300),
                child: _SectionLabel(
                  label: 'Birth time',
                  optional: true,
                ),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                child: Row(
                  children: [
                    Expanded(
                      child: _PickerRow(
                        icon: Icons.access_time_rounded,
                        value: _birthTime == null
                            ? 'Select a time'
                            : _birthTime!.format(context),
                        placeholder: _birthTime == null,
                        onTap: _birthTimeKnown ? _pickTime : null,
                        disabled: !_birthTimeKnown,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(
                        () => _birthTimeKnown = !_birthTimeKnown,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _birthTimeKnown
                              ? p.primary.withValues(alpha: 0.18)
                              : p.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _birthTimeKnown
                                ? p.primary
                                : p.glassBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _birthTimeKnown
                                  ? Icons.check_circle_rounded
                                  : Icons.help_outline_rounded,
                              size: 16,
                              color: _birthTimeKnown
                                  ? p.primary
                                  : p.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _birthTimeKnown ? 'Known' : 'Unknown',
                              style: TextStyle(
                                color: _birthTimeKnown
                                    ? p.primary
                                    : p.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              FadeSlideIn(
                delay: const Duration(milliseconds: 360),
                child: _SectionLabel(label: 'Birthplace'),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 380),
                child: BirthplaceSearch(
                  selectedPlace: _birthPlace,
                  onPlaceSelected: (place, lat, lng, tz) {
                    setState(() {
                      _birthPlace = place;
                      _lat = lat;
                      _lng = lng;
                      _tz = tz;
                    });
                  },
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: p.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: p.error, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              FadeSlideIn(
                delay: const Duration(milliseconds: 440),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_canSave && !_isLoading) ? _save : null,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Add & Generate Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: p.surfaceElevated,
                      disabledForegroundColor: p.textTertiary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(AppPalette p, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: p.textTertiary),
      filled: true,
      fillColor: p.surfaceElevated,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.optional = false});
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

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String value;
  final bool placeholder;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: p.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.glassBorder),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: disabled ? p.textTertiary : p.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: disabled
                      ? p.textTertiary
                      : placeholder
                          ? p.textTertiary
                          : p.textPrimary,
                  fontSize: 14,
                  fontWeight: placeholder
                      ? FontWeight.w400
                      : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
