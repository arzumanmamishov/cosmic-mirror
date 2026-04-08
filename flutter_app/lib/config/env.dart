enum Environment { dev, staging, prod }

class Env {
  Env._();

  static const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  static Environment get current {
    switch (environment) {
      case 'prod':
        return Environment.prod;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.dev;
    }
  }

  static String get apiBaseUrl {
    switch (current) {
      case Environment.prod:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://api.cosmicmirror.app',
        );
      case Environment.staging:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://staging-api.cosmicmirror.app',
        );
      case Environment.dev:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:8080',
        );
    }
  }

  static const revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: 'your_revenuecat_api_key',
  );

  static bool get isDev => current == Environment.dev;
  static bool get isProd => current == Environment.prod;
}
