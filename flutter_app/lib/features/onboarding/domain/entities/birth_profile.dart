import 'package:equatable/equatable.dart';

class BirthProfile extends Equatable {
  const BirthProfile({
    required this.birthDate,
    required this.birthPlace,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.birthTime,
    this.birthTimeKnown = true,
  });

  final DateTime birthDate;
  final DateTime? birthTime;
  final bool birthTimeKnown;
  final String birthPlace;
  final double latitude;
  final double longitude;
  final String timezone;

  @override
  List<Object?> get props => [
        birthDate,
        birthTime,
        birthTimeKnown,
        birthPlace,
        latitude,
        longitude,
        timezone,
      ];
}
