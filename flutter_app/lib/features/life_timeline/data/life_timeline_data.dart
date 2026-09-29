/// Personal life timeline events with the astrological context that was
/// active at the time. The "transits" field describes the major aspects
/// happening around that life event, derived from the user's natal chart.
library;

import 'package:cosmic_mirror/l10n/app_localizations.dart';
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
  String label(AppLocalizations l) {
    switch (this) {
      case LifeEventCategory.career:
        return l.lifeTimelineCatCareer;
      case LifeEventCategory.love:
        return l.lifeTimelineCatLove;
      case LifeEventCategory.growth:
        return l.lifeTimelineCatGrowth;
      case LifeEventCategory.loss:
        return l.lifeTimelineCatLoss;
      case LifeEventCategory.travel:
        return l.lifeTimelineCatTravel;
      case LifeEventCategory.family:
        return l.lifeTimelineCatFamily;
      case LifeEventCategory.reflection:
        return l.lifeTimelineCatReflection;
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

/// Mood ids stored on [LifeEvent.mood]. Keep these stable; map to display
/// text with [lifeEventMoodLabel].
const lifeEventMoods = [
  'Elated', 'Grounded', 'Open', 'Pressured',
  'Free', 'Cleansed', 'Tender', 'Resolved',
];

/// Localized label for a stored mood id. Unknown values are returned as-is.
String lifeEventMoodLabel(AppLocalizations l, String mood) {
  switch (mood) {
    case 'Elated':
      return l.lifeTimelineMoodElated;
    case 'Grounded':
      return l.lifeTimelineMoodGrounded;
    case 'Open':
      return l.lifeTimelineMoodOpen;
    case 'Pressured':
      return l.lifeTimelineMoodPressured;
    case 'Free':
      return l.lifeTimelineMoodFree;
    case 'Cleansed':
      return l.lifeTimelineMoodCleansed;
    case 'Tender':
      return l.lifeTimelineMoodTender;
    case 'Resolved':
      return l.lifeTimelineMoodResolved;
    default:
      return mood;
  }
}

/// Realistic mock data spanning the user's recent past, with believable
/// astrological context. Events are intentionally written like a real
/// person's journal entries, not lorem ipsum. Built per-locale so the sample
/// text is shown in the user's language.
List<LifeEvent> mockLifeEvents(AppLocalizations l) => [
  LifeEvent(
    id: 'evt_2024_03',
    date: DateTime(2024, 3, 14),
    title: l.lifeTimelineMock1Title,
    description: l.lifeTimelineMock1Desc,
    category: LifeEventCategory.career,
    transits: [l.lifeTimelineMock1Transit1, l.lifeTimelineMock1Transit2],
    mood: 'Elated',
  ),
  LifeEvent(
    id: 'evt_2024_07',
    date: DateTime(2024, 7, 5),
    title: l.lifeTimelineMock2Title,
    description: l.lifeTimelineMock2Desc,
    category: LifeEventCategory.reflection,
    transits: [l.lifeTimelineMock2Transit1, l.lifeTimelineMock2Transit2],
    mood: 'Grounded',
  ),
  LifeEvent(
    id: 'evt_2024_10',
    date: DateTime(2024, 10, 22),
    title: l.lifeTimelineMock3Title,
    description: l.lifeTimelineMock3Desc,
    category: LifeEventCategory.love,
    transits: [l.lifeTimelineMock3Transit1, l.lifeTimelineMock3Transit2],
    mood: 'Open',
  ),
  LifeEvent(
    id: 'evt_2025_02',
    date: DateTime(2025, 2, 11),
    title: l.lifeTimelineMock4Title,
    description: l.lifeTimelineMock4Desc,
    category: LifeEventCategory.growth,
    transits: [l.lifeTimelineMock4Transit1],
    mood: 'Pressured',
  ),
  LifeEvent(
    id: 'evt_2025_06',
    date: DateTime(2025, 6, 9),
    title: l.lifeTimelineMock5Title,
    description: l.lifeTimelineMock5Desc,
    category: LifeEventCategory.travel,
    transits: [l.lifeTimelineMock5Transit1, l.lifeTimelineMock5Transit2],
    mood: 'Free',
  ),
  LifeEvent(
    id: 'evt_2026_01',
    date: DateTime(2026, 1, 18),
    title: l.lifeTimelineMock6Title,
    description: l.lifeTimelineMock6Desc,
    category: LifeEventCategory.loss,
    transits: [l.lifeTimelineMock6Transit1, l.lifeTimelineMock6Transit2],
    mood: 'Cleansed',
  ),
];
