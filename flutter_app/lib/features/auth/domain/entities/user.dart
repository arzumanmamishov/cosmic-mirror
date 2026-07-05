import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.hasCompletedOnboarding = false,
  });

  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final bool hasCompletedOnboarding;

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    bool? hasCompletedOnboarding,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  @override
  List<Object?> get props =>
      [id, email, name, avatarUrl, hasCompletedOnboarding];
}
