import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../core/network/api_client.dart';

class BirthplaceSearch extends StatefulWidget {
  const BirthplaceSearch({
    required this.onPlaceSelected,
    super.key,
    this.selectedPlace,
  });

  final String? selectedPlace;
  final void Function(String place, double lat, double lng, String timezone)
      onPlaceSelected;

  @override
  State<BirthplaceSearch> createState() => _BirthplaceSearchState();
}

class _BirthplaceSearchState extends State<BirthplaceSearch> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<_PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    if (widget.selectedPlace != null) {
      _controller.text = widget.selectedPlace!;
      _showSuggestions = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isLoading = true);
    try {
      // In production, this calls a geocoding API (Google Places, Mapbox, etc.)
      // For now, we use the backend's place search endpoint
      final client = ApiClient();
      final results = await client.get<Map<String, dynamic>>(
        '/api/v1/places/search',
        queryParameters: {'q': query},
      );

      final places = (results['places'] as List<dynamic>?)
              ?.map(
                (p) => _PlaceSuggestion(
                  name: p['name'] as String,
                  latitude: (p['latitude'] as num).toDouble(),
                  longitude: (p['longitude'] as num).toDouble(),
                  timezone: p['timezone'] as String,
                ),
              )
              .toList() ??
          [];

      if (mounted) {
        setState(() {
          _suggestions = places;
          _showSuggestions = places.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _suggestions = [];
        });
      }
    }
  }

  void _selectPlace(_PlaceSuggestion place) {
    _controller.text = place.name;
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    _focusNode.unfocus();
    widget.onPlaceSelected(
      place.name,
      place.latitude,
      place.longitude,
      place.timezone,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (value) {
            _showSuggestions = true;
            _onSearchChanged(value);
          },
          decoration: InputDecoration(
            hintText: 'Search for a city...',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _suggestions = [];
                            _showSuggestions = false;
                          });
                        },
                      )
                    : null,
          ),
        ),
        if (_showSuggestions && _suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: CosmicColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CosmicColors.glassBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: CosmicColors.glassBorder,
              ),
              itemBuilder: (context, index) {
                final place = _suggestions[index];
                return ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: CosmicColors.primary,
                    size: 20,
                  ),
                  title: Text(place.name, style: CosmicTypography.bodyMedium),
                  dense: true,
                  onTap: () => _selectPlace(place),
                );
              },
            ),
          ),
        ],
        if (widget.selectedPlace != null && !_showSuggestions) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CosmicColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CosmicColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: CosmicColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.selectedPlace!,
                    style: CosmicTypography.bodySmall.copyWith(
                      color: CosmicColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PlaceSuggestion {
  const _PlaceSuggestion({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String timezone;
}
