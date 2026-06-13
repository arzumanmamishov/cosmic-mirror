import 'package:equatable/equatable.dart';

/// One of the nine octagram points (A,B,C,D,E,TL,TR,BR,BL). [arcana] is the
/// Major Arcana value 1..22 at that position.
class DestinyPoint extends Equatable {
  const DestinyPoint({
    required this.key,
    required this.position,
    required this.title,
    required this.arcana,
    required this.arcanaName,
    required this.meaning,
  });

  factory DestinyPoint.fromJson(Map<String, dynamic> json) {
    return DestinyPoint(
      key: json['key'] as String? ?? '',
      position: json['position'] as String? ?? '',
      title: json['title'] as String? ?? '',
      arcana: (json['arcana'] as num?)?.toInt() ?? 0,
      arcanaName: json['arcana_name'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
    );
  }

  final String key;
  final String position;
  final String title;
  final int arcana;
  final String arcanaName;
  final String meaning;

  @override
  List<Object?> get props => [key, arcana];
}

/// One of the four interpretive lines spanning three points.
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

/// One rung of the perimeter age-ladder: the year of life (1..80) and the
/// arcana (1..22) ruling it.
class AgeArcana extends Equatable {
  const AgeArcana({required this.age, required this.arcana});

  factory AgeArcana.fromJson(Map<String, dynamic> json) {
    return AgeArcana(
      age: (json['age'] as num?)?.toInt() ?? 0,
      arcana: (json['arcana'] as num?)?.toInt() ?? 0,
    );
  }

  final int age;
  final int arcana;

  @override
  List<Object?> get props => [age, arcana];
}

/// The full destiny matrix reading returned by GET /api/v1/destiny-matrix.
/// Points holds 15 entries (9 outer + 4 inner + 2 chakras); Lines holds 4;
/// ageLadder holds 80 rungs (ages 1..80) when the backend ships them.
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

  /// Returns the point for [key] (e.g. "A","E","TL"), or null when absent.
  DestinyPoint? pointFor(String key) {
    for (final p in points) {
      if (p.key == key) return p;
    }
    return null;
  }

  /// Returns the arcana for a given age (1..80), or 0 when the ladder isn't
  /// populated. Constant-time direct index — the ladder is always sorted.
  int arcanaForAge(int age) {
    if (age < 1 || age > ageLadder.length) return 0;
    return ageLadder[age - 1].arcana;
  }

  @override
  List<Object?> get props => [birthDate, points, lines, ageLadder];
}
