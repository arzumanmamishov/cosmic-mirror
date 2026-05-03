import 'package:equatable/equatable.dart';

/// The Rasi (D1) or any divisional Vedic chart, mirroring the Go domain
/// shape. JSON keys match the backend exactly so [VedicChart.fromJson] is
/// straightforward.
class VedicChart extends Equatable {
  const VedicChart({
    required this.ayanamsa,
    required this.ayanamsaValue,
    required this.lagna,
    required this.planets,
    required this.bhavas,
    required this.aspects,
    required this.atmaKaraka,
    required this.varga,
    required this.vargaName,
  });

  factory VedicChart.fromJson(Map<String, dynamic> json) {
    return VedicChart(
      ayanamsa: json['ayanamsa'] as String? ?? '',
      ayanamsaValue: (json['ayanamsa_value'] as num?)?.toDouble() ?? 0,
      lagna: VedicLagna.fromJson(
        (json['lagna'] as Map<String, dynamic>?) ?? const {},
      ),
      planets: ((json['planets'] as List<dynamic>?) ?? [])
          .map((e) => VedicPlanetPlacement.fromJson(e as Map<String, dynamic>))
          .toList(),
      bhavas: ((json['bhavas'] as List<dynamic>?) ?? [])
          .map((e) => VedicBhava.fromJson(e as Map<String, dynamic>))
          .toList(),
      aspects: ((json['aspects'] as List<dynamic>?) ?? [])
          .map((e) => VedicAspect.fromJson(e as Map<String, dynamic>))
          .toList(),
      atmaKaraka: json['atma_karaka'] as String? ?? '',
      varga: (json['varga'] as num?)?.toInt() ?? 1,
      vargaName: json['varga_name'] as String? ?? 'Rasi',
    );
  }

  /// "Lahiri", "Raman", "Krishnamurti", "Fagan-Bradley".
  final String ayanamsa;

  /// Current ayanamsa offset in degrees at birth.
  final double ayanamsaValue;

  final VedicLagna lagna;
  final List<VedicPlanetPlacement> planets;
  final List<VedicBhava> bhavas;
  final List<VedicAspect> aspects;

  /// Highest-degree planet — the soul significator (Atmakaraka).
  final String atmaKaraka;

  /// 1 for Rasi (D1), 9 for Navamsa, etc.
  final int varga;

  /// Human label: "Rasi", "Navamsa", ...
  final String vargaName;

  @override
  List<Object?> get props => [ayanamsa, varga, lagna, planets];
}

class VedicLagna extends Equatable {
  const VedicLagna({
    required this.sign,
    required this.signSanskrit,
    required this.degree,
    required this.longitude,
    required this.lord,
    required this.nakshatra,
    required this.pada,
  });

  factory VedicLagna.fromJson(Map<String, dynamic> json) {
    return VedicLagna(
      sign: json['sign'] as String? ?? '',
      signSanskrit: json['sign_sanskrit'] as String? ?? '',
      degree: (json['degree'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      lord: json['lord'] as String? ?? '',
      nakshatra: VedicNakshatra.fromJson(
        (json['nakshatra'] as Map<String, dynamic>?) ?? const {},
      ),
      pada: (json['pada'] as num?)?.toInt() ?? 1,
    );
  }

  final String sign;
  final String signSanskrit;
  final double degree;
  final double longitude;
  final String lord;
  final VedicNakshatra nakshatra;
  final int pada;

  @override
  List<Object?> get props => [sign, longitude];
}

class VedicPlanetPlacement extends Equatable {
  const VedicPlanetPlacement({
    required this.name,
    required this.sanskrit,
    required this.sign,
    required this.signSanskrit,
    required this.degree,
    required this.longitude,
    required this.house,
    required this.retrograde,
    required this.combust,
    required this.nakshatra,
    required this.pada,
    required this.dignity,
  });

  factory VedicPlanetPlacement.fromJson(Map<String, dynamic> json) {
    return VedicPlanetPlacement(
      name: json['name'] as String? ?? '',
      sanskrit: json['sanskrit'] as String? ?? '',
      sign: json['sign'] as String? ?? '',
      signSanskrit: json['sign_sanskrit'] as String? ?? '',
      degree: (json['degree'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      house: (json['house'] as num?)?.toInt() ?? 0,
      retrograde: json['retrograde'] as bool? ?? false,
      combust: json['combust'] as bool? ?? false,
      nakshatra: VedicNakshatra.fromJson(
        (json['nakshatra'] as Map<String, dynamic>?) ?? const {},
      ),
      pada: (json['pada'] as num?)?.toInt() ?? 1,
      dignity: json['dignity'] as String? ?? '',
    );
  }

  final String name;
  final String sanskrit;
  final String sign;
  final String signSanskrit;
  final double degree;
  final double longitude;
  final int house;
  final bool retrograde;
  final bool combust;
  final VedicNakshatra nakshatra;
  final int pada;
  final String dignity;

  @override
  List<Object?> get props => [name, sign, longitude];
}

class VedicBhava extends Equatable {
  const VedicBhava({
    required this.number,
    required this.sign,
    required this.signSanskrit,
    required this.lord,
    required this.description,
    required this.planets,
  });

  factory VedicBhava.fromJson(Map<String, dynamic> json) {
    return VedicBhava(
      number: (json['number'] as num?)?.toInt() ?? 0,
      sign: json['sign'] as String? ?? '',
      signSanskrit: json['sign_sanskrit'] as String? ?? '',
      lord: json['lord'] as String? ?? '',
      description: json['description'] as String? ?? '',
      planets: ((json['planets'] as List<dynamic>?) ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  final int number;
  final String sign;
  final String signSanskrit;
  final String lord;
  final String description;
  final List<String> planets;

  @override
  List<Object?> get props => [number, sign];
}

class VedicNakshatra extends Equatable {
  const VedicNakshatra({
    required this.index,
    required this.name,
    required this.ruler,
    required this.deity,
    required this.symbol,
    required this.gana,
    required this.nadi,
    required this.varna,
    required this.animal,
    required this.gender,
    required this.caste,
  });

  factory VedicNakshatra.fromJson(Map<String, dynamic> json) {
    return VedicNakshatra(
      index: (json['index'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      ruler: json['ruler'] as String? ?? '',
      deity: json['deity'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      gana: json['gana'] as String? ?? '',
      nadi: json['nadi'] as String? ?? '',
      varna: json['varna'] as String? ?? '',
      animal: json['animal'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      caste: json['caste'] as String? ?? '',
    );
  }

  final int index;
  final String name;
  final String ruler;
  final String deity;
  final String symbol;
  final String gana;
  final String nadi;
  final String varna;
  final String animal;
  final String gender;
  final String caste;

  @override
  List<Object?> get props => [index, name];
}

class VedicAspect extends Equatable {
  const VedicAspect({
    required this.from,
    required this.fromSanskrit,
    required this.to,
    required this.toHouse,
    required this.type,
    required this.strength,
  });

  factory VedicAspect.fromJson(Map<String, dynamic> json) {
    return VedicAspect(
      from: json['from'] as String? ?? '',
      fromSanskrit: json['from_sanskrit'] as String? ?? '',
      to: json['to'] as String? ?? '',
      toHouse: (json['to_house'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      strength: (json['strength'] as num?)?.toDouble() ?? 0,
    );
  }

  final String from;
  final String fromSanskrit;
  final String to; // graha name OR "House"
  final int toHouse;
  final String type; // "7th", "4th", "8th", ...
  final double strength;

  @override
  List<Object?> get props => [from, to, type];
}
