import 'package:flutter_test/flutter_test.dart';
import 'package:modern_trade_flutter/core/api_client.dart';
import 'package:modern_trade_flutter/core/app_config.dart';
import 'package:modern_trade_flutter/models/models.dart';
import 'package:modern_trade_flutter/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

const stateProduct = Product(
    id: 'p',
    name: 'Rice',
    brand: 'PASALHO',
    category: 'Food',
    description: '',
    imageUrl: '',
    price: 100,
    availability: 'AVAILABLE');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('production loads products only from the live API', () async {
    final requestedPaths = <String>[];
    final state = AppState(
      api: testApi((request) async {
        requestedPaths.add(request.url.path);
        if (request.url.path == '/api/public/stores') {
          return jsonResponse([
            {'id': 'store', 'name': 'PASALHO'}
          ]);
        }
        if (request.url.path == '/api/public/products') {
          return jsonResponse({
            'data': [
              {
                'id': 'live-product',
                'name': 'Live product',
                'price': 125,
              }
            ]
          });
        }
        if (request.url.path == '/api/public/categories') {
          return jsonResponse([
            {'id': 'category', 'name': 'Live category'}
          ]);
        }
        return jsonResponse({});
      }),
      configurationValidator: () => AppConfig.validate(
        environment: 'production',
        apiBaseUrl: 'https://api.pasalho.example',
        isRelease: true,
      ),
    );

    await state.initialize();

    expect(state.error, isNull);
    expect(state.products.map((product) => product.id), ['live-product']);
    expect(requestedPaths, contains('/api/public/products'));
    expect(requestedPaths, isNot(contains('/api/public/stores')));
  });

  test('demo initializes entirely from bundled fixtures without API calls',
      () async {
    var requestCount = 0;
    final state = AppState(
      demoMode: true,
      api: testApi((_) async {
        requestCount++;
        return jsonResponse({});
      }),
      configurationValidator: () => AppConfig.validate(
        environment: 'demo',
        apiBaseUrl: '',
        isRelease: true,
      ),
    );

    await state.initialize();

    expect(state.error, isNull);
    expect(state.products, hasLength(32));
    expect(state.categories, hasLength(10));
    expect(state.customer?.preferredName, 'Demo Customer');
    expect(requestCount, 0);
  });

  test('demo checkout saves a local DEMO order without API calls', () async {
    var requestCount = 0;
    final state = AppState(
      demoMode: true,
      api: testApi((_) async {
        requestCount++;
        return jsonResponse({});
      }),
    );
    await state.initialize();
    await state.addToCart(state.products.first);

    final order = await _checkout(state);

    expect(order.orderNumber, 'DEMO-1001');
    expect((await state.loadOrders()).single.id, 'DEMO-1001');
    expect(state.cart, isEmpty);
    expect(requestCount, 0);
  });

  test('unreachable production API exposes no fallback products', () async {
    final state = AppState(
      api: testApi((_) async => throw const ApiException('unreachable')),
      configurationValidator: () => null,
    );

    await state.initialize();

    expect(state.error, 'unreachable');
    expect(state.products, isEmpty);
    expect(state.categories, isEmpty);
  });

  test('missing production API URL fails before any request', () async {
    var requestCount = 0;
    final state = AppState(
      api: testApi((_) async {
        requestCount++;
        return jsonResponse({});
      }),
      configurationValidator: () => AppConfig.validate(
        environment: 'production',
        apiBaseUrl: '',
        isRelease: true,
      ),
    );

    await state.initialize();

    expect(state.error, 'Production API configuration is missing.');
    expect(state.products, isEmpty);
    expect(requestCount, 0);
  });

  test('checkout guards signed-in, central delivery, and cart requirements',
      () async {
    final state = AppState(api: testApi((_) async => jsonResponse({})))
      ..products = const [stateProduct];
    await state.addToCart(stateProduct);
    await expectLater(
        _checkout(state),
        throwsA(isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.authentication)));
    state.customer = const Customer(id: 'c');
    await expectLater(
        _checkout(state, deliveryType: 'PICKUP'), throwsA(isA<ApiException>()));
    await state.clearCart();
    await expectLater(_checkout(state, deliveryType: 'DELIVERY'),
        throwsA(isA<ApiException>()));
  });

  test('failed cart upload keeps local cart intact', () async {
    final state = AppState(api: testApi((request) async {
      if (request.url.path == '/api/shopping-cart') {
        return jsonResponse({'id': 'cart'});
      }
      return jsonResponse({'error': 'stock changed'}, 409);
    }))
      ..products = const [stateProduct]
      ..customer = const Customer(id: 'c');
    await state.addToCart(stateProduct);
    await expectLater(_checkout(state), throwsA(isA<ApiException>()));
    expect(state.cart, hasLength(1));
  });

  test('successful checkout clears local cart', () async {
    final state = AppState(api: testApi((request) async {
      if (request.url.path == '/api/shopping-cart') {
        return jsonResponse({'id': 'cart'});
      }
      if (request.url.path.endsWith('/items')) return jsonResponse({});
      return jsonResponse({'id': 'order'});
    }))
      ..products = const [stateProduct]
      ..customer = const Customer(id: 'c');
    await state.addToCart(stateProduct);
    expect((await _checkout(state)).id, 'order');
    expect(state.cart, isEmpty);
  });

  test(
      'initialize restores secure session and never falls back on invalid catalog',
      () async {
    final store = MemorySessionStore()..values['customer_session'] = 'session';
    final api = testApi((request) async {
      if (request.url.path == '/api/auth/session/validate') {
        return jsonResponse({
          'customer': {'id': 'restored'}
        });
      }
      return jsonResponse([]);
    }, store: store);
    final state = AppState(api: api);
    await state.initialize();
    expect(state.customer?.id, 'restored');
    expect(state.products, isEmpty);
    expect(state.error, isNotNull);
  });
}

Future<CustomerOrder> _checkout(AppState state,
        {String deliveryType = 'DELIVERY'}) =>
    state.checkout(
        deliveryType: deliveryType,
        name: 'Asha',
        phone: '9812345678',
        address: '',
        city: '',
        state: '',
        postalCode: '');
