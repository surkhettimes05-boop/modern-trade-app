import 'package:flutter_test/flutter_test.dart';
import 'package:modern_trade_flutter/core/api_client.dart';
import 'package:modern_trade_flutter/repositories/catalog_repository.dart';

import 'test_helpers.dart';

void main() {
  test('maps catalog responses and keeps unavailable products visible',
      () async {
    Uri? productRequest;
    final repo = CatalogRepository(testApi((request) async {
      if (request.url.path.endsWith('products')) {
        productRequest = request.url;
        return jsonResponse({
          'data': [
            {
              'id': 'p',
              'name': 'Soon',
              'price': '12.50',
              'availability_status': 'COMING_SOON'
            }
          ]
        });
      }
      if (request.url.path.endsWith('categories')) {
        return jsonResponse([
          {'id': 'c', 'name': 'Food'}
        ]);
      }
      return jsonResponse([
        {'id': 's', 'name': 'Store'}
      ]);
    }));
    final result = await repo.load();
    expect(result.products.single.priceMinor, 1250);
    expect(result.products.single.isAvailable, isFalse);
    expect(result.categories.single.id, 'c');
    expect(productRequest?.queryParameters.containsKey('store_id'), isFalse);
  });

  test('empty or invalid product response reports an error without fixtures',
      () async {
    final repo = CatalogRepository(
        testApi((_) async => jsonResponse({'unexpected': true})));
    await expectLater(
        repo.load(),
        throwsA(isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.invalidResponse)));
  });
}
