import 'package:equatable/equatable.dart';

/// One octagram point. [key] is a stable identifier (e.g. "day", "center",
/// "tl", "heaven", "arm_left_1", "diag_tl_3"); [arcana] is the Major Arcana
/// value 1..22 at that position.
class DestinyPoint extends Equatable {
  const DestinyPoint({
    required this.key,
    required this.position,
    required this.title,
    required this.arcana,
    required this.arcanaName,
    required this.meaning,
    this.detailedMeaning = '',
  });

  factory DestinyPoint.fromJson(Map<String, dynamic> json) {
    return DestinyPoint(
      key: json['key'] as String? ?? '',
      position: json['position'] as String? ?? '',
      title: json['title'] as String? ?? '',
      arcana: (json['arcana'] as num?)?.toInt() ?? 0,
      arcanaName: json['arcana_name'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      detailedMeaning: json['detailed_meaning'] as String? ?? '',
    );
  }

  final String key;
  final String position;
  final String title;
  final int arcana;
  final String arcanaName;
  final String meaning;

  /// Long-form interpretation (server-generated, universal per arcana). Falls
  /// back to [meaning] when empty.
  final String detailedMeaning;

  /// The richest available text for this point.
  String get bestMeaning => detailedMeaning.isNotEmpty ? detailedMeaning : meaning;

  @override
  List<Object?> get props => [key, arcana];
}

/// One interpretive line spanning an ordered list of point keys.
class DestinyLine extends Equatable {
  const DestinyLine({
    required this.key,
    required this.title,
    required this.pointKeys,
    required this.theme,
  });

  factory DestinyLine.fromJson(Map<String, dynamic> json) {
    return DestinyLine(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      pointKeys: ((json['point_keys'] as List<dynamic>?) ?? const [])
          .map((e) => e as String? ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      theme: json['theme'] as String? ?? '',
    );
  }

  final String key;
  final String title;
  final List<String> pointKeys;
  final String theme;

  @override
  List<Object?> get props => [key, pointKeys];
}

/// One rung of the perimeter age-ladder: a (possibly fractional) age, a
/// readable label, and the arcana (1..22) ruling it.
class AgeArcana extends Equatable {
  const AgeArcana({
    required this.age,
    required this.label,
    required this.arcana,
  });

  factory AgeArcana.fromJson(Map<String, dynamic> json) {
    final age = (json['age'] as num?)?.toDouble() ?? 0;
    return AgeArcana(
      age: age,
      label: json['label'] as String? ?? _defaultLabel(age),
      arcana: (json['arcana'] as num?)?.toInt() ?? 0,
    );
  }

  /// Fallback label if the backend ever omits one — whole numbers drop the
  /// decimal, otherwise two decimal places.
  static String _defaultLabel(double age) {
    if (age == age.roundToDouble()) return age.toInt().toString();
    return age.toStringAsFixed(2);
  }

  final double age;
  final String label;
  final int arcana;

  /// True for the eight decade corner anchors (ages 0,10,...,70).
  bool get isCorner => age % 10 == 0;

  @override
  List<Object?> get props => [age, arcana];
}

/// The full Matrix of Destiny reading returned by GET /api/v1/destiny-matrix.
class DestinyMatrixReading extends Equatable {
  const DestinyMatrixReading({
    required this.birthDate,
    required this.points,
    required this.lines,
    required this.ageLadder,
  });

  factory DestinyMatrixReading.fromJson(Map<String, dynamic> json) {
    final pointList = (json['points'] as List?) ?? const [];
    final lineList = (json['lines'] as List?) ?? const [];
    final ladderList = (json['age_ladder'] as List?) ?? const [];
    return DestinyMatrixReading(
      birthDate: json['birth_date'] as String? ?? '',
      points: pointList
          .whereType<Map<String, dynamic>>()
          .map(DestinyPoint.fromJson)
          .toList(),
      lines: lineList
          .whereType<Map<String, dynamic>>()
          .map(DestinyLine.fromJson)
          .toList(),
      ageLadder: ladderList
          .whereType<Map<String, dynamic>>()
          .map(AgeArcana.fromJson)
          .toList(),
    );
  }

  final String birthDate;
  final List<DestinyPoint> points;
  final List<DestinyLine> lines;
  final List<AgeArcana> ageLadder;

  /// Returns the point for [key] (e.g. "day","center","tl"), or null.
  DestinyPoint? pointFor(String key) {
    for (final p in points) {
      if (p.key == key) return p;
    }
    return null;
  }

  /// Returns the arcana value for [key], or 0 when the point is absent.
  int arcanaFor(String key) => pointFor(key)?.arcana ?? 0;

  @override
  List<Object?> get props => [birthDate, points, lines, ageLadder];
}
