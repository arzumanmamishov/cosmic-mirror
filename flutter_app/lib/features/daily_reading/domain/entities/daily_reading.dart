import 'package:equatable/equatable.dart';

class DailyReading extends Equatable {
  const DailyReading({
    required this.id,
    required this.readingDate,
    required this.energyLevel,
    required this.emotional,
    required this.love,
    required this.career,
    required this.health,
    required this.caution,
    required this.action,
    required this.affirmation,
    required this.luckyColor,
    required this.luckyNumber,
    this.sunSign,
    this.moonSign,
    this.risingSign,
  });

  final String id;
  final DateTime readingDate;
  final int energyLevel;
  final String emotional;
  final String love;
  final String career;
  final String health;
  final String caution;
  final String action;
  final String affirmation;
  final String luckyColor;
  final int luckyNumber;
  final String? sunSign;
  final String? moonSign;
  final String? risingSign;

  @override
  List<Object?> get props => [id, readingDate];
}
