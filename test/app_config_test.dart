import 'package:flutter_test/flutter_test.dart';
import 'package:modern_trade_flutter/core/app_config.dart';

void main() {
  test('development configuration has an explicit API URL', () {
    expect(AppConfig.environment, 'development');
    expect(Uri.parse(AppConfig.apiBaseUrl).host, isNotEmpty);
    expect(AppConfig.configurationError(), isNull);
  });

  test('production accepts an explicit HTTPS API URL', () {
    expect(
      AppConfig.validate(
        environment: 'production',
        apiBaseUrl: 'https://storesync-backend-dg8z.onrender.com',
        isRelease: true,
      ),
      isNull,
    );
  });

  test('production rejects a missing API URL', () {
    expect(
      AppConfig.validate(
        environment: 'production',
        apiBaseUrl: '',
        isRelease: true,
      ),
      'Production API configuration is missing.',
    );
  });

  test('production rejects a non-HTTPS API URL', () {
    expect(
      AppConfig.validate(
        environment: 'production',
        apiBaseUrl: 'http://api.pasalho.example',
        isRelease: true,
      ),
      'Production API traffic must use HTTPS.',
    );
  });
}
