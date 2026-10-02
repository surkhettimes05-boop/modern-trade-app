import 'package:flutter_test/flutter_test.dart';
import 'package:modern_trade_flutter/demo/demo_product_assets.dart';
import 'package:modern_trade_flutter/models/models.dart';

void main() {
  test('maps canonical demo SKUs to bundled artwork', () {
    expect(
      DemoProductAssets.forSku(DemoProductAssets.saanjhMasoorDal1kg),
      'assets/images/products/saanjh-masoor-dal-1kg.webp',
    );
    expect(
      DemoProductAssets.forSku(DemoProductAssets.gharChamakToiletCleaner500ml),
      'assets/images/products/gharchamak-toilet-cleaner-500ml.webp',
    );
    expect(
      DemoProductAssets.allForSku(
          DemoProductAssets.gharChamakToiletCleaner500ml),
      hasLength(4),
    );
    expect(
      DemoProductAssets.forSku(DemoProductAssets.avaruMomoAcharMasala50g),
      'assets/images/products/avaru-momo-achar-masala-50g.webp',
    );
  });

  test('uses bundled SKU artwork instead of a remote product URL', () {
    const product = Product(
      id: 'demo-product',
      sku: DemoProductAssets.saanjhChanaDal1kg,
      name: 'Chana Dal',
      brand: 'Saanjh',
      category: 'Dal & Pulses',
      description: '',
      imageUrl: 'https://example.invalid/chana.png',
      price: 250,
      availability: 'AVAILABLE',
    );

    expect(
      DemoProductAssets.imageFor(product),
      'assets/images/products/saanjh-chana-dal-1kg.webp',
    );
  });

  test('keeps non-demo products on their configured image source', () {
    const product = Product(
      id: 'regular-product',
      sku: 'REGULAR-SKU',
      name: 'Regular product',
      brand: '',
      category: 'Daily essentials',
      description: '',
      imageUrl: 'https://example.com/product.png',
      price: 100,
      availability: 'AVAILABLE',
    );

    expect(DemoProductAssets.imageFor(product), product.imageUrl);
  });
}
