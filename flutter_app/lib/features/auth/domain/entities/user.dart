import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.hasCompletedOnboarding = false,
  });

  final String id;
  final String email;
  final String? name;
  final bool hasCompletedOnboarding;

  @override
  List<Object?> get props => [id, email, name, hasCompletedOnboarding];
}
