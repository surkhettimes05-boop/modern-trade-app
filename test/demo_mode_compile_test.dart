import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modern_trade_flutter/core/app_config.dart';
import 'package:modern_trade_flutter/state/app_state.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test(
    'APP_ENV=demo selects local data without an API request',
    () async {
      var requests = 0;

      final state = AppState(
        api: testApi((_) async {
          requests++;
          return jsonResponse({});
        }),
      );

      await state.initialize();

      expect(state.error, isNull);
      expect(state.products, isNotEmpty);
      expect(state.selectedStore?.id, 'demo-birendranagar');
      expect(state.customer?.id, 'demo-customer');
      expect(requests, 0);
    },
    skip: !AppConfig.isDemo,
  );
}