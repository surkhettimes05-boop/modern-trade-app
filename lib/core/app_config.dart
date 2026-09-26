import 'package:flutter/foundation.dart';

class AppConfig {
  static const environment =
      String.fromEnvironment('APP_ENV', defaultValue: 'development');
  static const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _developmentApiBaseUrl = String.fromEnvironment(
      'DEVELOPMENT_API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3001');

  static String get apiBaseUrl => _configuredApiBaseUrl.isNotEmpty
      ? _configuredApiBaseUrl
      : environment == 'development'
          ? _developmentApiBaseUrl
          : '';

  static String? configurationError() => validate(
        environment: environment,
        apiBaseUrl: apiBaseUrl,
        isRelease: kReleaseMode,
      );

  static String? validate({
    required String environment,
    required String apiBaseUrl,
    required bool isRelease,
  }) {
    if (environment != 'development' && environment != 'production') {
      return 'APP_ENV must be development or production.';
    }
    if (isRelease && environment != 'production') {
      return 'This release build is missing APP_ENV=production.';
    }
    if (environment == 'production' && apiBaseUrl.isEmpty) {
      return 'Production API configuration is missing.';
    }
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'The API base URL is invalid.';
    }
    if (environment == 'production' && uri.scheme != 'https') {
      return 'Production API traffic must use HTTPS.';
    }
    return null;
  }

  static const maxCartQuantity =
      int.fromEnvironment('MAX_CART_QUANTITY', defaultValue: 99);
  static const supportPhone = String.fromEnvironment('SUPPORT_PHONE');
  static const privacyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
  static const termsUrl = String.fromEnvironment('TERMS_URL');
}
