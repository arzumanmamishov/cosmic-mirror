import 'dart:async';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Birthplace search — a Lively-styled search field, a results list, and
/// a confirmation chip once a place is chosen.
class BirthplaceSearch extends StatefulWidget {
  const BirthplaceSearch({
    required this.onPlaceSelected,
    super.key,
    this.selectedPlace,
    this.onPlaceCleared,
  });

  final String? selectedPlace;
  final void Function(String place, double lat, double lng, String timezone)
      onPlaceSelected;

  /// Called when the user edits or clears the text after a place was
  /// selected — the old selection no longer matches the field.
  final VoidCallback? onPlaceCleared;

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
  // Set when the last search failed or returned nothing, so the user gets
  // feedback instead of a silently empty list.
  bool _searchFailed = false;
  bool _noResults = false;
  // Monotonic id of the latest search — responses from older, slower
  // requests are dropped so they can't overwrite newer results.
  int _searchSeq = 0;

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

  void _onSearchChanged(String rawQuery) {
    _debounce?.cancel();
    if (widget.selectedPlace != null) widget.onPlaceCleared?.call();
    final query = rawQuery.trim();
    if (query.length < 3) {
      _searchSeq++;
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isLoading = false;
        _searchFailed = false;
        _noResults = false;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchPlaces(query),
    );
  }

  Future<void> _searchPlaces(String query) async {
    final seq = ++_searchSeq;
    setState(() {
      _isLoading = true;
      _searchFailed = false;
      _noResults = false;
    });
    try {
      final client = ApiClient();
      final results = await client.get<Map<String, dynamic>>(
        '/api/v1/places/search',
        queryParameters: {'q': query},
      );
      final places = (results['places'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>()
              .map(
                (p) => _PlaceSuggestion(
                  name: p['name'] as String,
                  latitude: (p['latitude'] as num).toDouble(),
                  longitude: (p['longitude'] as num).toDouble(),
                  timezone: p['timezone'] as String,
                ),
              )
              .toList() ??
          [];
      if (mounted && seq == _searchSeq) {
        setState(() {
          _suggestions = places;
          _showSuggestions = places.isNotEmpty;
          _noResults = places.isEmpty;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && seq == _searchSeq) {
        setState(() {
          _isLoading = false;
          _suggestions = [];
          _searchFailed = true;
        });
      }
    }
  }

  void _selectPlace(_PlaceSuggestion place) {
    _debounce?.cancel();
    _searchSeq++;
    _controller.text = place.name;
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
      _isLoading = false;
      _noResults = false;
      _searchFailed = false;
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
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // search field — fill = page background, per the design brief
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: p.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focusNode.hasFocus ? p.primary : p.line,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: p.textMuted, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  cursorColor: p.primary,
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.words,
                  autocorrect: false,
                  onChanged: (value) {
                    _showSuggestions = true;
                    _onSearchChanged(value);
                  },
                  onTap: () => setState(() {}),
                  style: LivelyType.h2(p.textPrimary)
                      .copyWith(fontWeight: FontWeight.w400),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: l10n.placesSearchHint,
                    hintStyle: LivelyType.h2(p.textDim)
                        .copyWith(fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              if (_isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(p.primary),
                  ),
                )
              else if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    _onSearchChanged('');
                  },
                  behavior: HitTestBehavior.opaque,
                  // Padded so the clear "x" is a comfortable tap target.
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                    child: Icon(
                      Icons.close_rounded,
                      color: p.textMuted,
                      size: 18,
                      semanticLabel:
                          MaterialLocalizations.of(context).deleteButtonTooltip,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // results list
        if (_showSuggestions && _suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? p.surfaceGlass : p.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, thickness: 1, color: p.line),
                itemBuilder: (context, index) {
                  final place = _suggestions[index];
                  return InkWell(
                    onTap: () => _selectPlace(place),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: p.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(Icons.location_on_rounded,
                                color: p.primary, size: 16,),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              place.name,
                              style: LivelyType.body(p.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Capped so long zone ids (America/Argentina/…)
                          // can't push the row past narrow screens.
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 96),
                            child: Text(
                              place.timezone,
                              style: LivelyType.mono(p.textMuted, size: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
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

        if (!_isLoading && (_searchFailed || _noResults)) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _searchFailed
                  ? l10n.oaphPlaceSearchFailed
                  : l10n.oaphPlaceSearchNoResults,
              style: LivelyType.small(_searchFailed ? p.error : p.textMuted),
            ),
          ),
        ],

        // confirmation chip
        if (widget.selectedPlace != null && !_showSuggestions) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.glassBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: p.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.selectedPlace!,
                    style: LivelyType.body(p.textPrimary),
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
