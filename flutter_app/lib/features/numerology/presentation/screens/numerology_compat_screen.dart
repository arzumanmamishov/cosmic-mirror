import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/numerology/domain/entities/numerology.dart';
import 'package:cosmic_mirror/features/numerology/presentation/providers/numerology_providers.dart';
import 'package:cosmic_mirror/features/numerology/presentation/widgets/compat_score_panel.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NumerologyCompatScreen extends ConsumerStatefulWidget {
  const NumerologyCompatScreen({super.key});

  @override
  ConsumerState<NumerologyCompatScreen> createState() =>
      _NumerologyCompatScreenState();
}

class _NumerologyCompatScreenState
    extends ConsumerState<NumerologyCompatScreen> {
  final _name = TextEditingController();
  DateTime? _birthDate;
  NumerologyCompatibility? _result;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _name.text.trim().isNotEmpty && _birthDate != null && !_busy;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(numerologyRepositoryProvider).compareWith(
                fullName: _name.text.trim(),
                birthDate: _birthDate!,
              );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context).compatibilityTitle),
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
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
            children: [
              _field(p, 'PARTNER FULL BIRTH NAME', _name, 'e.g. Sarah Anne Chen'),
              const SizedBox(height: 14),
              _datePicker(p),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _busy ? 'Calculating…' : 'Compute compatibility',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: p.error, fontSize: 12)),
              ],
              if (_result != null) ...[
                const SizedBox(height: 32),
                CompatScorePanel(report: _result!),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(
    AppPalette p,
    String label,
    TextEditingController c,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.glassBorder),
          ),
          child: TextField(
            controller: c,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: p.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: p.textTertiary, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePicker(AppPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PARTNER BIRTH DATE',
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.glassBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: p.textSecondary, size: 16),
                const SizedBox(width: 10),
                Text(
                  _birthDate == null
                      ? 'Tap to pick'
                      : '${_birthDate!.year}-'
                          '${_birthDate!.month.toString().padLeft(2, '0')}-'
                          '${_birthDate!.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color:
                        _birthDate == null ? p.textTertiary : p.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
