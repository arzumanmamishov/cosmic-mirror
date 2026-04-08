import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
  });

  final int? statusCode;

  @override
  List<Object?> get props => [message, code, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Please check your internet connection and try again.',
    super.code = 'network_error',
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Unable to load cached data.',
    super.code = 'cache_error',
  });
}

class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code = 'auth_error',
  });
}

class SubscriptionFailure extends Failure {
  const SubscriptionFailure({
    super.message = 'This feature requires a premium subscription.',
    super.code = 'subscription_required',
  });
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 'validation_error',
    this.field,
  });

  final String? field;

  @override
  List<Object?> get props => [message, code, field];
}

class RateLimitFailure extends Failure {
  const RateLimitFailure({
    super.message = 'You have reached your daily limit. Upgrade to Premium for unlimited access.',
    super.code = 'rate_limit',
  });
}
