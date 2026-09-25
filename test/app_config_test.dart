import 'package:flutter_test/flutter_test.dart';
import 'package:modern_trade_flutter/core/app_config.dart';

void main() {
  test('development configuration has an explicit API URL', () {
    expect(AppConfig.environment, 'development');
    expect(Uri.parse(AppConfig.apiBaseUrl).host, isNotEmpty);
    expect(AppConfig.configurationError(), isNull);
  });
}
