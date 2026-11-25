import 'dart:convert';

import 'package:cosmic_mirror/features/life_timeline/data/life_timeline_data.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On-device persistence for the user's own life-timeline moments. There is
/// no backend for these yet, so without this every added moment was lost as
/// soon as the screen closed. Scoped per user id so a second account on the
/// same device never sees someone else's moments.
class LifeTimelineStorage {
  const LifeTimelineStorage(this.userId);

  final String? userId;

  String get _key => 'life_timeline_events_v1_${userId ?? 'anon'}';

  Future<List<LifeEvent>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(_fromJson)
          .whereType<LifeEvent>()
          .toList();
    } catch (e) {
      debugPrint('[LifeTimeline] load failed: $e');
      return [];
    }
  }

  Future<bool> save(List<LifeEvent> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(
        _key,
        jsonEncode(events.map(_toJson).toList()),
      );
    } catch (e) {
      debugPrint('[LifeTimeline] save failed: $e');
      return false;
    }
  }

  /// Removes this user's moments from the device (account deletion).
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('[LifeTimeline] clear failed: $e');
    }
  }

  static Map<String, dynamic> _toJson(LifeEvent e) => {
        'id': e.id,
        'date': e.date.toIso8601String(),
        'title': e.title,
        'description': e.description,
        'category': e.category.name,
        if (e.mood != null) 'mood': e.mood,
      };

  static LifeEvent? _fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date'] as String? ?? '');
    final title = json['title'] as String? ?? '';
    if (date == null || title.isEmpty) return null;
    final categoryName = json['category'] as String?;
    final category = LifeEventCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => LifeEventCategory.reflection,
    );
    return LifeEvent(
      id: json['id'] as String? ?? 'evt_${date.millisecondsSinceEpoch}',
      date: date,
      title: title,
      description: json['description'] as String? ?? '',
      category: category,
      // Transits for user moments aren't calculated yet — show none rather
      // than a placeholder that never resolves.
      transits: const [],
      mood: json['mood'] as String?,
    );
  }
}
