import 'dart:convert';
import 'dart:typed_data';

import 'package:cosmic_mirror/core/error/exceptions.dart';
import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/features/auth/data/models/auth_tokens.dart';
import 'package:cosmic_mirror/features/auth/presentation/auth_errors.dart';
import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmic_mirror/l10n/app_localizations_en.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with [status] and [body].
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body);
  final int status;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

AuthTokens _tokens() {
  final now = DateTime.now();
  return AuthTokens.fromJson({
    'access_token': 'access',
    'access_expires_at': now.add(const Duration(minutes: 15)).toIso8601String(),
    'refresh_token': 'refresh',
    'refresh_expires_at': now.add(const Duration(days: 30)).toIso8601String(),
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('authErrorMessage', () {
    final l = AppLocalizationsEn();

    test('maps the backend error code, not the message text', () {
      // The wrong-password case used to fall through to "Something went
      // wrong": the code isn't part of the exception's toString().
      expect(
        authErrorMessage(
          l,
          const AuthException(
            message: 'Email or password is incorrect',
            code: 'invalid_credentials',
          ),
        ),
        l.authErrorInvalidCredential,
      );
      expect(
        authErrorMessage(
          l,
          const ServerException(
            message: 'x',
            statusCode: 403,
            code: 'account_banned',
          ),
        ),
        l.authAccountSuspended,
      );
      expect(
        authErrorMessage(
          l,
          const ServerException(
            message: 'x',
            statusCode: 409,
            code: 'email_in_use',
          ),
        ),
        l.authEmailAlreadyRegistered,
      );
      expect(
        authErrorMessage(
          l,
          const ServerException(
            message: 'x',
            statusCode: 400,
            code: 'invalid_code',
          ),
        ),
        l.authOtpInvalidCode,
      );
      expect(
        authErrorMessage(
          l,
          const ServerException(
            message: 'x',
            statusCode: 404,
            code: 'user_not_found',
          ),
          noAccount: 'no account',
        ),
        'no account',
      );
      expect(
        authErrorMessage(
          l,
          const RateLimitException(code: 'account_locked'),
          rateLimited: 'slow down',
        ),
        'slow down',
      );
      expect(authErrorMessage(l, const NetworkException()), l.authErrorNetwork);
      expect(
        authErrorMessage(l, Exception('boom')),
        l.commonSomethingWentWrong,
      );
    });

    test('isPasswordTooLong counts bytes like the server', () {
      expect(isPasswordTooLong('a' * 72), isFalse);
      expect(isPasswordTooLong('a' * 73), isTrue);
      // "ş" is 2 bytes in UTF-8: 37 of them are 74 bytes.
      expect(isPasswordTooLong('ş' * 37), isTrue);
    });
  });

  group('ending a session', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    ProviderContainer signedIn() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(currentUserProvider.notifier).hydrateFromAuth(
            id: 'user-1',
            name: 'Alice',
            email: 'alice@example.com',
            avatarUrl: null,
            hasCompletedOnboarding: true,
          );
      return c;
    }

    test('an expired session forgets the user', () async {
      final c = signedIn();
      await c.read(authControllerProvider.future);
      c.read(authControllerProvider.notifier).sessionExpired();
      expect(c.read(currentUserProvider).id, isNull);
      expect(c.read(authControllerProvider).valueOrNull, isNull);
      expect(c.read(signOutReasonProvider), isNull);
    });

    test('a suspended account is signed out with a reason', () async {
      final c = signedIn();
      await c.read(authControllerProvider.future);
      c.read(authControllerProvider.notifier).accountSuspended();
      expect(c.read(currentUserProvider).id, isNull);
      expect(c.read(signOutReasonProvider), SignOutReason.accountSuspended);
    });

    test('sign-out wipes the stored session', () async {
      final c = signedIn();
      await authStorage.write(_tokens());
      await c.read(authControllerProvider.future);
      // /auth/logout is best-effort; with no server it just fails quietly.
      await c.read(authControllerProvider.notifier).logout();
      expect(await authStorage.read(), isNull);
      expect(c.read(currentUserProvider).id, isNull);
      expect(c.read(authControllerProvider).valueOrNull, isNull);
    });

    test("the next account doesn't inherit the previous profile", () {
      final c = signedIn();
      c.read(currentUserProvider.notifier).markOnboardingComplete(
            sunSign: 'Leo',
            moonSign: 'Aries',
            risingSign: 'Virgo',
          );
      c.read(currentUserProvider.notifier).hydrateFromAuth(
            id: 'user-2',
            name: '',
            email: 'bob@example.com',
            avatarUrl: null,
            hasCompletedOnboarding: false,
          );
      final u = c.read(currentUserProvider);
      expect(u.id, 'user-2');
      expect(u.name, '');
      expect(u.sunSign, isNull);
      expect(u.hasCompletedOnboarding, isFalse);
    });
  });

  group('ApiClient', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('account_banned ends the session and reports a suspension', () async {
      await authStorage.write(_tokens());
      var suspended = false;
      var expired = false;
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
        ..httpClientAdapter = _FakeAdapter(403, {
          'error': {'code': 'account_banned', 'message': 'suspended'},
        });
      final client = ApiClient(
        dio: dio,
        onSessionExpired: () => expired = true,
        onAccountSuspended: () => suspended = true,
      );

      await expectLater(
        client.get<Map<String, dynamic>>('/api/v1/users/me'),
        throwsA(
          isA<ServerException>()
              .having((e) => e.code, 'code', 'account_banned'),
        ),
      );
      expect(suspended, isTrue);
      expect(expired, isFalse);
      expect(await authStorage.read(), isNull);
    });

    test('an ordinary 403 leaves the session alone', () async {
      await authStorage.write(_tokens());
      var suspended = false;
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
        ..httpClientAdapter = _FakeAdapter(403, {
          'error': {'code': 'premium_required', 'message': 'premium'},
        });
      final client =
          ApiClient(dio: dio, onAccountSuspended: () => suspended = true);

      await expectLater(
        client.get<Map<String, dynamic>>('/api/v1/timeline'),
        throwsA(isA<ServerException>()),
      );
      expect(suspended, isFalse);
      expect(await authStorage.read(), isNotNull);
    });
  });
}
