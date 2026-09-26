import '../models/models.dart';
import 'demo_product_assets.dart';

/// Explicitly local, presentation-only records for APP_ENV=demo.
/// These records are never sent to or loaded from the production API.
abstract final class DemoData {
  static const customer = Customer(
    id: 'demo-customer',
    preferredName: 'Demo Customer',
    phoneMasked: '98XXXXXXXX',
    verificationStatus: 'DEMO',
  );

  static const stores = [
    StoreLocation(
      id: 'demo-birendranagar',
      name: 'PASALHO Birendranagar',
      address: 'Birendranagar, Surkhet',
      hours: '9:00 AM – 8:00 PM',
    ),
  ];

  static const categories = [
    ProductCategory(id: 'dal', name: 'Dal & Pulses', slug: 'dal-pulses'),
    ProductCategory(id: 'rice', name: 'Rice', slug: 'rice'),
    ProductCategory(id: 'flour', name: 'Flour', slug: 'flour'),
    ProductCategory(id: 'oil', name: 'Cooking Oil', slug: 'cooking-oil'),
    ProductCategory(id: 'spices', name: 'Spices', slug: 'spices'),
    ProductCategory(id: 'snacks', name: 'Biscuits & Snacks', slug: 'snacks'),
    ProductCategory(id: 'beverages', name: 'Beverages', slug: 'beverages'),
    ProductCategory(id: 'care', name: 'Personal Care', slug: 'personal-care'),
    ProductCategory(
        id: 'cleaning', name: 'Household Cleaning', slug: 'cleaning'),
    ProductCategory(
        id: 'essentials', name: 'Daily Essentials', slug: 'essentials'),
  ];

  static const addresses = [
    {
      'id': 'demo-home',
      'address_type': 'HOME',
      'recipient_name': 'Demo Customer',
      'phone': '9812345678',
      'street': 'Main Road, Ward 6',
      'tole_locality': 'Birendranagar',
      'city': 'Birendranagar',
      'state': 'Karnali Province',
      'postal_code': '21700',
      'is_default': true,
    },
  ];

  static final products = <Product>[
    _p('avaru-momo', DemoProductAssets.avaruMomoAcharMasala50g,
        'Momo Achar Masala', 'AVARU', 'spices', 'Spices', 85, '50 g'),
    _p('saanjh-chana', DemoProductAssets.saanjhChanaDal1kg, 'Chana Dal',
        'SAANJH', 'dal', 'Dal & Pulses', 215, '1 kg'),
    _p('saanjh-masoor', DemoProductAssets.saanjhMasoorDal1kg, 'Masoor Dal',
        'SAANJH', 'dal', 'Dal & Pulses', 235, '1 kg'),
    _p('saanjh-moong', DemoProductAssets.saanjhMoongDal1kg, 'Moong Dal',
        'SAANJH', 'dal', 'Dal & Pulses', 275, '1 kg'),
    _p(
        'saanjh-whole-chana',
        DemoProductAssets.saanjhWholeChana1kg,
        'Whole Chana (Kala Chana)',
        'SAANJH',
        'dal',
        'Dal & Pulses',
        190,
        '1 kg'),
    _p('saanjh-rahar', DemoProductAssets.saanjhRaharDal1kg, 'Rahar Dal',
        'SAANJH', 'dal', 'Dal & Pulses', 260, '1 kg'),
    _p(
        'gharchamak-dishwash',
        DemoProductAssets.gharChamakDishwashLiquid500ml,
        'Dishwash Liquid – Lemon Fresh',
        'GHARCHAMAK',
        'cleaning',
        'Household Cleaning',
        145,
        '500 ml'),
    _p(
        'gharchamak-floor',
        DemoProductAssets.gharChamakFloorCleaner500ml,
        'Floor Cleaner – Fresh Home',
        'GHARCHAMAK',
        'cleaning',
        'Household Cleaning',
        165,
        '500 ml'),
    _p(
        'gharchamak-toilet',
        DemoProductAssets.gharChamakToiletCleaner500ml,
        'Toilet Cleaner – Power Clean',
        'GHARCHAMAK',
        'cleaning',
        'Household Cleaning',
        155,
        '500 ml'),
    _p(
        'timur-chiura',
        DemoProductAssets.timurMasalaChiuraMix50g,
        'Timur Masala Chiura Mix',
        'YOG',
        'snacks',
        'Biscuits & Snacks',
        50,
        '50 g'),
    _p('yuga-bhujiya', DemoProductAssets.yugaBhujiya10Rs, 'Bhujiya', 'YUGA',
        'snacks', 'Biscuits & Snacks', 10, '35 g'),
    _p('yuga-peanuts', DemoProductAssets.yugaRoastedPeanuts10Rs,
        'Roasted Peanuts', 'YUGA', 'snacks', 'Biscuits & Snacks', 10, '35 g'),
    _p('basmati-rice', null, 'Basmati Rice', 'PASALHO Select', 'rice', 'Rice',
        185, '1 kg'),
    _p('jeera-rice', null, 'Jeera Masino Rice', 'PASALHO Select', 'rice',
        'Rice', 145, '1 kg'),
    _p('atta', null, 'Whole Wheat Atta', 'PASALHO Daily', 'flour', 'Flour', 95,
        '1 kg'),
    _p('maida', null, 'All Purpose Flour', 'PASALHO Daily', 'flour', 'Flour',
        70, '1 kg'),
    _p('mustard-oil', null, 'Mustard Oil', 'PASALHO Daily', 'oil',
        'Cooking Oil', 285, '1 L'),
    _p('sunflower-oil', null, 'Sunflower Oil', 'PASALHO Daily', 'oil',
        'Cooking Oil', 240, '1 L'),
    _p('turmeric', null, 'Turmeric Powder', 'Kitchen Choice', 'spices',
        'Spices', 55, '100 g'),
    _p('cumin', null, 'Cumin Seeds', 'Kitchen Choice', 'spices', 'Spices', 75,
        '100 g'),
    _p('tea', null, 'CTC Tea', 'Himalayan Cup', 'beverages', 'Beverages', 120,
        '250 g'),
    _p('juice', null, 'Mixed Fruit Juice', 'Fresh Day', 'beverages',
        'Beverages', 80, '1 L'),
    _p('soap', null, 'Bath Soap', 'Fresh Care', 'care', 'Personal Care', 45,
        '125 g'),
    _p('shampoo', null, 'Daily Shampoo', 'Fresh Care', 'care', 'Personal Care',
        135, '340 ml'),
    _p('toothpaste', null, 'Herbal Toothpaste', 'Fresh Care', 'care',
        'Personal Care', 95, '150 g'),
    _p('tissue', null, 'Facial Tissue', 'PASALHO Daily', 'essentials',
        'Daily Essentials', 80, '200 pulls'),
    _p('eggs', null, 'Farm Eggs', 'Local Fresh', 'essentials',
        'Daily Essentials', 210, '12 pcs'),
    _p('salt', null, 'Iodized Salt', 'PASALHO Daily', 'essentials',
        'Daily Essentials', 30, '1 kg'),
    _p('sugar', null, 'Fine Sugar', 'PASALHO Daily', 'essentials',
        'Daily Essentials', 90, '1 kg'),
    _p('biscuits', null, 'Butter Biscuits', 'Tea Time', 'snacks',
        'Biscuits & Snacks', 65, '200 g'),
    _p('noodles', null, 'Instant Noodles', 'Quick Bite', 'snacks',
        'Biscuits & Snacks', 25, '70 g'),
    _p('laundry', null, 'Laundry Detergent', 'Home Care', 'cleaning',
        'Household Cleaning', 180, '1 kg'),
  ];

  static Product _p(String id, String? sku, String name, String brand,
      String categoryId, String category, double price, String unit) {
    return Product(
      id: 'demo-$id',
      sku: sku,
      name: name,
      brand: brand,
      categoryId: categoryId,
      category: category,
      unit: unit,
      description:
          'DEMO DATA · A locally bundled product for the PASALHO investor presentation.',
      imageUrl: '',
      price: price,
      originalPrice: price + 15,
      rating: 4.6,
      reviewCount: 24,
      availability: 'AVAILABLE',
    );
  }
}
