import '../../domain/entities/birth_profile.dart';

class BirthProfileModel extends BirthProfile {
  const BirthProfileModel({
    required super.birthDate,
    required super.birthPlace,
    required super.latitude,
    required super.longitude,
    required super.timezone,
    super.birthTime,
    super.birthTimeKnown,
  });

  factory BirthProfileModel.fromJson(Map<String, dynamic> json) {
    return BirthProfileModel(
      birthDate: DateTime.parse(json['birth_date'] as String),
      birthTime: json['birth_time'] != null
          ? DateTime.parse('2000-01-01 ${json['birth_time']}')
          : null,
      birthTimeKnown: json['birth_time_known'] as bool? ?? true,
      birthPlace: json['birth_place'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'birth_date':
          '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
      if (birthTime != null)
        'birth_time':
            '${birthTime!.hour.toString().padLeft(2, '0')}:${birthTime!.minute.toString().padLeft(2, '0')}',
      'birth_time_known': birthTimeKnown,
      'birth_place': birthPlace,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
    };
  }
}
