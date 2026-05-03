/// Personal life timeline events with the astrological context that was
/// active at the time. The "transits" field describes the major aspects
/// happening around that life event, derived from the user's natal chart.
library;

import 'package:flutter/material.dart';

enum LifeEventCategory {
  career,
  love,
  growth,
  loss,
  travel,
  family,
  reflection,
}

class LifeEvent {
  const LifeEvent({
    required this.id,
    required this.date,
    required this.title,
    required this.description,
    required this.category,
    required this.transits,
    this.mood,
  });

  final String id;
  final DateTime date;
  final String title;
  final String description;
  final LifeEventCategory category;
  final List<String> transits;
  final String? mood;
}

extension LifeEventCategoryUI on LifeEventCategory {
  String get label {
    switch (this) {
      case LifeEventCategory.career:
        return 'Career';
      case LifeEventCategory.love:
        return 'Love';
      case LifeEventCategory.growth:
        return 'Growth';
      case LifeEventCategory.loss:
        return 'Loss';
      case LifeEventCategory.travel:
        return 'Travel';
      case LifeEventCategory.family:
        return 'Family';
      case LifeEventCategory.reflection:
        return 'Reflection';
    }
  }

  IconData get icon {
    switch (this) {
      case LifeEventCategory.career:
        return Icons.work_rounded;
      case LifeEventCategory.love:
        return Icons.favorite_rounded;
      case LifeEventCategory.growth:
        return Icons.spa_rounded;
      case LifeEventCategory.loss:
        return Icons.cloud_rounded;
      case LifeEventCategory.travel:
        return Icons.flight_rounded;
      case LifeEventCategory.family:
        return Icons.home_rounded;
      case LifeEventCategory.reflection:
        return Icons.auto_stories_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LifeEventCategory.career:
        return const Color(0xFFB8860B);
      case LifeEventCategory.love:
        return const Color(0xFFE14B8A);
      case LifeEventCategory.growth:
        return const Color(0xFF5ED39A);
      case LifeEventCategory.loss:
        return const Color(0xFF8E8BA3);
      case LifeEventCategory.travel:
        return const Color(0xFF4DA3FF);
      case LifeEventCategory.family:
        return const Color(0xFFC76E5E);
      case LifeEventCategory.reflection:
        return const Color(0xFF7B61FF);
    }
  }
}

/// Realistic mock data spanning the user's recent past, with believable
/// astrological context. Events are intentionally written like a real
/// person's journal entries, not lorem ipsum.
final List<LifeEvent> mockLifeEvents = [
  LifeEvent(
    id: 'evt_2024_03',
    date: DateTime(2024, 3, 14),
    title: 'Got the offer',
    description:
        'Accepted the senior role at the design studio. Felt like everything I\'ve worked toward suddenly clicked into place.',
    category: LifeEventCategory.career,
    transits: ['Jupiter trine natal MC', 'Venus in 10th house'],
    mood: 'Elated',
  ),
  LifeEvent(
    id: 'evt_2024_07',
    date: DateTime(2024, 7, 5),
    title: 'Cancer New Moon retreat',
    description:
        'Three days off-grid in Joshua Tree. Wrote 40 pages of journal. Came back with clarity about what I actually want.',
    category: LifeEventCategory.reflection,
    transits: ['New Moon conjunct natal Moon', 'Mercury retrograde in 4th'],
    mood: 'Grounded',
  ),
  LifeEvent(
    id: 'evt_2024_10',
    date: DateTime(2024, 10, 22),
    title: 'Met Theo',
    description:
        'Coffee at 4pm became dinner became a long walk. Felt the kind of recognition you can\'t fake.',
    category: LifeEventCategory.love,
    transits: ['Venus trine natal Sun', 'Sun in 7th house'],
    mood: 'Open',
  ),
  LifeEvent(
    id: 'evt_2025_02',
    date: DateTime(2025, 2, 11),
    title: 'Saturn return begins',
    description:
        'The first wave hit. Re-evaluating every commitment. Starting to feel which structures need to come down.',
    category: LifeEventCategory.growth,
    transits: ['Saturn conjunct natal Saturn (1st pass)'],
    mood: 'Pressured',
  ),
  LifeEvent(
    id: 'evt_2025_06',
    date: DateTime(2025, 6, 9),
    title: 'Trip to Lisbon',
    description:
        'Two weeks alone with my notebook. Realised how much of my anxiety was just being too plugged in.',
    category: LifeEventCategory.travel,
    transits: ['Jupiter in 9th house', 'Mars trine Mercury'],
    mood: 'Free',
  ),
  LifeEvent(
    id: 'evt_2026_01',
    date: DateTime(2026, 1, 18),
    title: 'Ended the lease',
    description:
        'Moved out of the apartment. Decided I needed less space and fewer attachments. Saturn was right.',
    category: LifeEventCategory.loss,
    transits: ['Saturn square natal Moon', 'Pluto opposite natal Venus'],
    mood: 'Cleansed',
  ),
];
