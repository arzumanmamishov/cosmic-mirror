import '../../domain/entities/daily_reading.dart';

class DailyReadingModel extends DailyReading {
  const DailyReadingModel({
    required super.id,
    required super.readingDate,
    required super.energyLevel,
    required super.emotional,
    required super.love,
    required super.career,
    required super.health,
    required super.caution,
    required super.action,
    required super.affirmation,
    required super.luckyColor,
    required super.luckyNumber,
    super.sunSign,
    super.moonSign,
    super.risingSign,
  });

  factory DailyReadingModel.fromJson(Map<String, dynamic> json) {
    return DailyReadingModel(
      id: json['id'] as String,
      readingDate: DateTime.parse(json['reading_date'] as String),
      energyLevel: json['energy_level'] as int,
      emotional: json['emotional'] as String,
      love: json['love'] as String,
      career: json['career'] as String,
      health: json['health'] as String,
      caution: json['caution'] as String,
      action: json['action'] as String,
      affirmation: json['affirmation'] as String,
      luckyColor: json['lucky_color'] as String,
      luckyNumber: json['lucky_number'] as int,
      sunSign: json['sun_sign'] as String?,
      moonSign: json['moon_sign'] as String?,
      risingSign: json['rising_sign'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reading_date': readingDate.toIso8601String(),
      'energy_level': energyLevel,
      'emotional': emotional,
      'love': love,
      'career': career,
      'health': health,
      'caution': caution,
      'action': action,
      'affirmation': affirmation,
      'lucky_color': luckyColor,
      'lucky_number': luckyNumber,
    };
  }
}
