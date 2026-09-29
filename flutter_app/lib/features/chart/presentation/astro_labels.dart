import 'package:cosmic_mirror/core/utils/string_utils.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Display-name mappings for astrology identifiers returned by the backend.
///
/// The API sends English identifiers ("Aries", "Sun", "trine", "fire") that
/// are also used for lookups (glyphs, colors, geometry). These helpers turn
/// them into localized display strings without touching the identifiers.
/// Unknown values fall through unchanged.

/// Western zodiac order — index matches [chartSignAbbrs].
const chartSignOrder = [
  'Aries',
  'Taurus',
  'Gemini',
  'Cancer',
  'Leo',
  'Virgo',
  'Libra',
  'Scorpio',
  'Sagittarius',
  'Capricorn',
  'Aquarius',
  'Pisces',
];

String chartSignName(AppLocalizations l, String sign) {
  switch (sign) {
    case 'Aries':
      return l.chartSignAries;
    case 'Taurus':
      return l.chartSignTaurus;
    case 'Gemini':
      return l.chartSignGemini;
    case 'Cancer':
      return l.chartSignCancer;
    case 'Leo':
      return l.chartSignLeo;
    case 'Virgo':
      return l.chartSignVirgo;
    case 'Libra':
      return l.chartSignLibra;
    case 'Scorpio':
      return l.chartSignScorpio;
    case 'Sagittarius':
      return l.chartSignSagittarius;
    case 'Capricorn':
      return l.chartSignCapricorn;
    case 'Aquarius':
      return l.chartSignAquarius;
    case 'Pisces':
      return l.chartSignPisces;
    default:
      return sign;
  }
}

/// Short sign labels (Aries → "Ar" / "Koç") in zodiac order.
List<String> chartSignAbbrs(AppLocalizations l) => [
      l.chartSignAbbrAries,
      l.chartSignAbbrTaurus,
      l.chartSignAbbrGemini,
      l.chartSignAbbrCancer,
      l.chartSignAbbrLeo,
      l.chartSignAbbrVirgo,
      l.chartSignAbbrLibra,
      l.chartSignAbbrScorpio,
      l.chartSignAbbrSagittarius,
      l.chartSignAbbrCapricorn,
      l.chartSignAbbrAquarius,
      l.chartSignAbbrPisces,
    ];

String chartPlanetName(AppLocalizations l, String name) {
  switch (name) {
    case 'Sun':
      return l.chartPlanetSun;
    case 'Moon':
      return l.chartPlanetMoon;
    case 'Mercury':
      return l.chartPlanetMercury;
    case 'Venus':
      return l.chartPlanetVenus;
    case 'Mars':
      return l.chartPlanetMars;
    case 'Jupiter':
      return l.chartPlanetJupiter;
    case 'Saturn':
      return l.chartPlanetSaturn;
    case 'Uranus':
      return l.chartPlanetUranus;
    case 'Neptune':
      return l.chartPlanetNeptune;
    case 'Pluto':
      return l.chartPlanetPluto;
    case 'North Node':
      return l.chartPlanetNorthNode;
    case 'South Node':
      return l.chartPlanetSouthNode;
    case 'Chiron':
      return l.chartPlanetChiron;
    default:
      // Rahu, Ketu and other Sanskrit names stay transliterated.
      return name;
  }
}

/// Two-letter graha abbreviation from the localized name
/// (Sun → "Su" / "Gü", Jupiter → "Ju" / "Jü").
String chartPlanetAbbr(AppLocalizations l, String name) =>
    chartPlanetName(l, name).abbrev();

String chartAspectName(AppLocalizations l, String type) {
  switch (type.toLowerCase()) {
    case 'conjunction':
      return l.chartLegendConjunction;
    case 'sextile':
      return l.chartLegendSextile;
    case 'square':
      return l.chartLegendSquare;
    case 'trine':
      return l.chartLegendTrine;
    case 'opposition':
      return l.chartLegendOpposition;
    case 'quincunx':
      return l.chartAspectQuincunx;
    default:
      return type.capitalizeFirst();
  }
}

String chartElementName(AppLocalizations l, String element) {
  switch (element.toLowerCase()) {
    case 'fire':
      return l.chartElementFire;
    case 'earth':
      return l.chartElementEarth;
    case 'air':
      return l.chartElementAir;
    case 'water':
      return l.chartElementWater;
    default:
      return element.capitalizeFirst();
  }
}

/// Locale-aware uppercase. Dart's [String.toUpperCase] maps 'i' → 'I', which
/// is wrong for Turkish (should be 'İ').
String chartUpper(BuildContext context, String s) {
  if (Localizations.localeOf(context).languageCode == 'tr') {
    return s.replaceAll('i', 'İ').toUpperCase();
  }
  return s.toUpperCase();
}
