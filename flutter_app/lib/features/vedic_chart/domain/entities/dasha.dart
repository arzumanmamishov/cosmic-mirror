import 'package:equatable/equatable.dart';

class DashaPeriod extends Equatable {
  const DashaPeriod({
    required this.lord,
    required this.level,
    required this.startDate,
    required this.endDate,
    this.sub = const [],
  });

  factory DashaPeriod.fromJson(Map<String, dynamic> json) {
    return DashaPeriod(
      lord: json['lord'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      startDate: DateTime.tryParse(json['start_date'] as String? ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] as String? ?? '') ??
          DateTime.now(),
      sub: ((json['sub'] as List<dynamic>?) ?? [])
          .map((e) => DashaPeriod.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String lord;
  final int level; // 1=maha, 2=antar, 3=pratyantar
  final DateTime startDate;
  final DateTime endDate;
  final List<DashaPeriod> sub;

  Duration get duration => endDate.difference(startDate);

  bool containsMoment(DateTime t) =>
      !t.isBefore(startDate) && t.isBefore(endDate);

  @override
  List<Object?> get props => [lord, level, startDate, endDate];
}

class DashaPath extends Equatable {
  const DashaPath({
    required this.maha,
    required this.antar,
    required this.pratyantar,
    required this.at,
  });

  factory DashaPath.fromJson(Map<String, dynamic> json) {
    return DashaPath(
      maha: json['maha'] as String? ?? '',
      antar: json['antar'] as String? ?? '',
      pratyantar: json['pratyantar'] as String? ?? '',
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String maha;
  final String antar;
  final String pratyantar;
  final DateTime at;

  @override
  List<Object?> get props => [maha, antar, pratyantar];
}

class DashaTree extends Equatable {
  const DashaTree({
    required this.system,
    required this.levels,
    required this.current,
    required this.mahadashas,
  });

  factory DashaTree.fromJson(Map<String, dynamic> json) {
    return DashaTree(
      system: json['system'] as String? ?? 'Vimshottari',
      levels: (json['levels'] as num?)?.toInt() ?? 3,
      current: DashaPath.fromJson(
        (json['current'] as Map<String, dynamic>?) ?? const {},
      ),
      mahadashas: ((json['mahadashas'] as List<dynamic>?) ?? [])
          .map((e) => DashaPeriod.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String system;
  final int levels;
  final DashaPath current;
  final List<DashaPeriod> mahadashas;

  @override
  List<Object?> get props => [system, levels, mahadashas];
}
