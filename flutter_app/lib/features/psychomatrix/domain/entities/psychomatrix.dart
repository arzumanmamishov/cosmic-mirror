import 'package:equatable/equatable.dart';

/// The four derived working numbers of the Alexandrov psychomatrix method.
class PsychomatrixWorkingNumbers extends Equatable {
  const PsychomatrixWorkingNumbers({
    required this.first,
    required this.second,
    required this.third,
    required this.fourth,
  });

  factory PsychomatrixWorkingNumbers.fromJson(Map<String, dynamic> json) {
    return PsychomatrixWorkingNumbers(
      first: (json['first'] as num?)?.toInt() ?? 0,
      second: (json['second'] as num?)?.toInt() ?? 0,
      third: (json['third'] as num?)?.toInt() ?? 0,
      fourth: (json['fourth'] as num?)?.toInt() ?? 0,
    );
  }

  final int first;
  final int second;
  final int third;
  final int fourth;

  @override
  List<Object?> get props => [first, second, third, fourth];
}

/// One of the nine grid cells (digit 1..9) with its occurrence count and text.
class PsychomatrixCell extends Equatable {
  const PsychomatrixCell({
    required this.digit,
    required this.count,
    required this.repeated,
    required this.title,
    required this.meaning,
  });

  factory PsychomatrixCell.fromJson(Map<String, dynamic> json) {
    return PsychomatrixCell(
      digit: (json['digit'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      repeated: json['repeated'] as String? ?? '',
      title: json['title'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
    );
  }

  final int digit;
  final int count;

  /// The digit rendered [count] times, e.g. "111", or "" when absent.
  final String repeated;
  final String title;
  final String meaning;

  bool get isEmpty => count <= 0;

  @override
  List<Object?> get props => [digit, count];
}

/// One of the eight lines (rows, columns, diagonals) of the grid.
class PsychomatrixLine extends Equatable {
  const PsychomatrixLine({
    required this.key,
    required this.title,
    required this.cells,
    required this.strength,
    required this.meaning,
  });

  factory PsychomatrixLine.fromJson(Map<String, dynamic> json) {
    return PsychomatrixLine(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      cells: ((json['cells'] as List<dynamic>?) ?? const [])
          .map((e) => (e as num?)?.toInt() ?? 0)
          .toList(),
      strength: (json['strength'] as num?)?.toInt() ?? 0,
      meaning: json['meaning'] as String? ?? '',
    );
  }

  final String key;
  final String title;
  final List<int> cells;

  /// Total digit count across the line's three cells.
  final int strength;
  final String meaning;

  @override
  List<Object?> get props => [key, strength];
}

/// The full psychomatrix reading returned by GET /api/v1/psychomatrix.
class PsychomatrixReading extends Equatable {
  const PsychomatrixReading({
    required this.birthDate,
    required this.workingNumbers,
    required this.cells,
    required this.lines,
  });

  factory PsychomatrixReading.fromJson(Map<String, dynamic> json) {
    final cellList = (json['cells'] as List<dynamic>?) ?? const [];
    final lineList = (json['lines'] as List<dynamic>?) ?? const [];
    return PsychomatrixReading(
      birthDate: json['birth_date'] as String? ?? '',
      workingNumbers: PsychomatrixWorkingNumbers.fromJson(
        (json['working_numbers'] as Map<String, dynamic>?) ?? const {},
      ),
      cells: cellList
          .whereType<Map<String, dynamic>>()
          .map(PsychomatrixCell.fromJson)
          .toList(),
      lines: lineList
          .whereType<Map<String, dynamic>>()
          .map(PsychomatrixLine.fromJson)
          .toList(),
    );
  }

  final String birthDate;
  final PsychomatrixWorkingNumbers workingNumbers;
  final List<PsychomatrixCell> cells;
  final List<PsychomatrixLine> lines;

  /// Returns the cell for [digit] (1..9), or null when not present.
  PsychomatrixCell? cellFor(int digit) {
    for (final c in cells) {
      if (c.digit == digit) return c;
    }
    return null;
  }

  @override
  List<Object?> get props => [birthDate, workingNumbers, cells, lines];
}
