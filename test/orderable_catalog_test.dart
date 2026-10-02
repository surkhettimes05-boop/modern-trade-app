import 'package:flutter_test/flutter_test.dart';
import 'package:modern_trade_flutter/models/models.dart';
import 'package:modern_trade_flutter/repositories/cart_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Product product(String status) => Product.fromJson({
        'id': 'product',
        'name': 'Rice',
        'price': '100',
        'availability_status': status
      });
  test('checkout-confirmed availability can be ordered without claiming stock',
      () async {
    final item = product('CHECK_AT_CHECKOUT');
    expect(item.isAvailable, isFalse);
    expect(item.canOrder, isTrue);
    final cart = CartController();
    await cart.add(item);
    await cart.set(item, 3);
    final restored = CartController();
    await restored.restore([item]);
    expect(restored.quantities['product'], 3);
  });
  test('blocked and unknown inventory cannot enter the basket', () async {
    for (final status in ['BLOCKED', 'OUT_OF_STOCK', 'FUTURE_UNKNOWN', '']) {
      final item = product(status);
      expect(item.canOrder, isFalse);
      final cart = CartController();
      await cart.add(item);
      expect(cart.quantities, isEmpty);
    }
  });
}
