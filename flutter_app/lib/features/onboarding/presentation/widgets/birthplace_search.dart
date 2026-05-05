import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';

const _kGold = Color(0xFFD4B16A);
const _kSurface = Color(0xFF1A1F2E);
const _kSurfaceElevated = Color(0xFF1F2436);
const _kBorder = Color(0xFF2A2F3E);
const _kTextPrimary = Colors.white;
const _kTextSecondary = Color(0xFFB6BAC4);
const _kTextTertiary = Color(0xFF7E8290);

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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input — same style as the auth email/password fields.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: _kTextTertiary,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  cursorColor: _kGold,
                  onChanged: (value) {
                    _showSuggestions = true;
                    _onSearchChanged(value);
                  },
                  style: GoogleFonts.poppins(
                    color: _kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Search for a city…',
                    hintStyle: GoogleFonts.poppins(
                      color: _kTextTertiary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(_kGold),
                  ),
                )
              else if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    setState(() {
                      _suggestions = [];
                      _showSuggestions = false;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(
                    Icons.close_rounded,
                    color: _kTextTertiary,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),

        // Suggestions panel — flexible so it never overflows. ListView
        // already scrolls internally; the outer Flexible bounds the
        // height to whatever vertical space is available.
        if (_showSuggestions && _suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: _kSurfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: _kBorder,
                ),
                itemBuilder: (context, index) {
                  final place = _suggestions[index];
                  return InkWell(
                    onTap: () => _selectPlace(place),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: _kGold,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              place.name,
                              style: GoogleFonts.poppins(
                                color: _kTextPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // Confirmation chip — shown after a place was selected.
        if (widget.selectedPlace != null && !_showSuggestions) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kGold.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: _kGold,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.selectedPlace!,
                    style: GoogleFonts.poppins(
                      color: _kTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
