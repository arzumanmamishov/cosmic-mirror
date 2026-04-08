import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/cosmic_button.dart';
import '../../../onboarding/presentation/widgets/birth_date_picker.dart';
import '../../../onboarding/presentation/widgets/birthplace_search.dart';

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
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameController.text.trim().length >= 2 &&
      _birthDate != null &&
      _birthPlace != null;

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
          'birth_date':
              '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Person')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Who would you like to compare charts with?",
                style: CosmicTypography.headlineSmall),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Their name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Text('Birth Date', style: CosmicTypography.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: BirthDatePicker(
                selectedDate: _birthDate,
                onDateChanged: (d) => setState(() => _birthDate = d),
              ),
            ),
            const SizedBox(height: 20),
            Text('Birthplace', style: CosmicTypography.titleMedium),
            const SizedBox(height: 8),
            BirthplaceSearch(
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
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style: CosmicTypography.bodySmall.copyWith(
                    color: CosmicColors.error,
                  )),
            ],
            const SizedBox(height: 32),
            CosmicButton(
              label: 'Add & Generate Report',
              isLoading: _isLoading,
              onPressed: _canSave ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
