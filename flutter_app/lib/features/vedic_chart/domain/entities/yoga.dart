import 'package:equatable/equatable.dart';

class VedicYoga extends Equatable {
  const VedicYoga({
    required this.name,
    required this.sanskrit,
    required this.category,
    required this.description,
    required this.active,
    required this.strength,
    required this.planets,
  });

  factory VedicYoga.fromJson(Map<String, dynamic> json) {
    return VedicYoga(
      name: json['name'] as String? ?? '',
      sanskrit: json['sanskrit'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      strength: (json['strength'] as num?)?.toDouble() ?? 0,
      planets: ((json['planets'] as List<dynamic>?) ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  final String name;
  final String sanskrit;
  final String category;
  final String description;
  final bool active;
  final double strength;
  final List<String> planets;

  @override
  List<Object?> get props => [name, active, strength];
}

class ShadbalaBreakdown extends Equatable {
  const ShadbalaBreakdown({
    required this.sthana,
    required this.dig,
    required this.kala,
    required this.chesta,
    required this.naisargika,
    required this.drik,
    required this.total,
    required this.required,
    required this.sufficient,
  });

  factory ShadbalaBreakdown.fromJson(Map<String, dynamic> json) {
    return ShadbalaBreakdown(
      sthana: (json['sthana'] as num?)?.toDouble() ?? 0,
      dig: (json['dig'] as num?)?.toDouble() ?? 0,
      kala: (json['kala'] as num?)?.toDouble() ?? 0,
      chesta: (json['chesta'] as num?)?.toDouble() ?? 0,
      naisargika: (json['naisargika'] as num?)?.toDouble() ?? 0,
      drik: (json['drik'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      required: (json['required'] as num?)?.toDouble() ?? 0,
      sufficient: json['sufficient'] as bool? ?? false,
    );
  }

  final double sthana;
  final double dig;
  final double kala;
  final double chesta;
  final double naisargika;
  final double drik;
  final double total;
  final double required;
  final bool sufficient;

  @override
  List<Object?> get props => [sthana, dig, kala, chesta, naisargika, drik];
}

class Ashtakavarga extends Equatable {
  const Ashtakavarga({
    required this.sarva,
    required this.bhinn,
  });

  factory Ashtakavarga.fromJson(Map<String, dynamic> json) {
    final rawSarva = (json['sarva'] as List<dynamic>?) ?? const [];
    final sarva = List<int>.generate(
      12,
      (i) => i < rawSarva.length ? (rawSarva[i] as num).toInt() : 0,
    );
    final rawBhinn = (json['bhinn'] as Map<String, dynamic>?) ?? const {};
    final bhinn = <String, List<int>>{};
    rawBhinn.forEach((k, v) {
      final list = (v as List<dynamic>?) ?? const [];
      bhinn[k] = List<int>.generate(
        12,
        (i) => i < list.length ? (list[i] as num).toInt() : 0,
      );
    });
    return Ashtakavarga(sarva: sarva, bhinn: bhinn);
  }

  final List<int> sarva; // length 12
  final Map<String, List<int>> bhinn; // each value length 12

  @override
  List<Object?> get props => [sarva, bhinn];
}
