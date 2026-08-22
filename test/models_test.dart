import 'package:flutter_test/flutter_test.dart';
import 'package:modern_trade_flutter/models/models.dart';

void main() {
  test('maps StoreSync product fields', () {
    final product = Product.fromJson({
      'id': 'product-id',
      'name': 'Basmati Rice',
      'brand': 'NOVA MART',
      'category_name': 'Rice',
      'price': '799',
      'original_price': 999,
      'availability_status': 'AVAILABLE',
    });

    expect(product.id, 'product-id');
    expect(product.price, 799);
    expect(product.discountPercent, 20);
    expect(product.isAvailable, isTrue);
  });

  test('formats Nepalese rupee prices', () {
    expect(formatNpr(123456), 'NPR 123,456');
  });
}
