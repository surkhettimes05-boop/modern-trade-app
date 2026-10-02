import '../models/models.dart';

/// Bundled product artwork used by the offline investor-demo catalog.
///
/// Keep the SKU mapping explicit: filenames must never be inferred from product
/// names because names are presentation copy and can change independently.
abstract final class DemoProductAssets {
  static const avaruMomoAcharMasala50g = 'DEMO-AVARU-MOMO-ACHAR-MASALA-50G';
  static const saanjhChanaDal1kg = 'DEMO-SAANJH-CHANA-DAL-1KG';
  static const saanjhMasoorDal1kg = 'DEMO-SAANJH-MASOOR-DAL-1KG';
  static const saanjhMoongDal1kg = 'DEMO-SAANJH-MOONG-DAL-1KG';
  static const saanjhWholeChana1kg = 'DEMO-SAANJH-WHOLE-CHANA-1KG';
  static const saanjhRaharDal1kg = 'DEMO-SAANJH-RAHAR-DAL-1KG';
  static const gharChamakDishwashLiquid500ml =
      'DEMO-GHARCHAMAK-DISHWASH-LIQUID-LEMON-FRESH-500ML';
  static const gharChamakFloorCleaner500ml =
      'DEMO-GHARCHAMAK-FLOOR-CLEANER-FRESH-HOME-500ML';
  static const gharChamakToiletCleaner500ml =
      'DEMO-GHARCHAMAK-TOILET-CLEANER-POWER-CLEAN-500ML';
  static const timurMasalaChiuraMix50g = 'DEMO-TIMUR-MASALA-CHIURA-MIX-50G';
  static const yugaBhujiya10Rs = 'DEMO-YUGA-BHUJIYA-10RS';
  static const yugaRoastedPeanuts10Rs = 'DEMO-YUGA-ROASTED-PEANUTS-10RS';

  static const _bySku = <String, List<String>>{
    'AVARU-MOMO-ACHAR-MASALA-50G': [
      'assets/images/products/avaru-momo-achar-masala-50g.webp',
    ],
    'SAANJH-CHANA-DAL-1KG': [
      'assets/images/products/saanjh-chana-dal-1kg.webp',
    ],
    'SAANJH-MASOOR-DAL-1KG': [
      'assets/images/products/saanjh-masoor-dal-1kg.webp',
    ],
    'SAANJH-MOONG-DAL-1KG': [
      'assets/images/products/saanjh-moong-dal-1kg.webp',
    ],
    'SAANJH-WHOLE-CHANA-1KG': [
      'assets/images/products/saanjh-whole-chana-1kg.webp',
    ],
    'SAANJH-KALA-CHANA-1KG': [
      'assets/images/products/saanjh-whole-chana-1kg.webp',
    ],
    'SAANJH-RAHAR-DAL-1KG': [
      'assets/images/products/saanjh-rahar-dal-1kg.webp',
    ],
    'GHARCHAMAK-DISHWASH-LIQUID-LEMON-FRESH-500ML': [
      'assets/images/products/gharchamak-dishwash-liquid-500ml.webp',
      'assets/images/products/gharchamak-dishwash-liquid-packaging.webp',
      'assets/images/products/gharchamak-cleaning-range.webp',
      'assets/images/products/gharchamak-cleaning-range-alt.webp',
    ],
    'GHARCHAMAK-FLOOR-CLEANER-FRESH-HOME-500ML': [
      'assets/images/products/gharchamak-floor-cleaner-500ml.webp',
      'assets/images/products/gharchamak-floor-cleaner-packaging.webp',
      'assets/images/products/gharchamak-cleaning-range.webp',
      'assets/images/products/gharchamak-cleaning-range-alt.webp',
    ],
    'GHARCHAMAK-TOILET-CLEANER-POWER-CLEAN-500ML': [
      'assets/images/products/gharchamak-toilet-cleaner-500ml.webp',
      'assets/images/products/gharchamak-toilet-cleaner-packaging.webp',
      'assets/images/products/gharchamak-cleaning-range.webp',
      'assets/images/products/gharchamak-cleaning-range-alt.webp',
    ],
    'TIMUR-MASALA-CHIURA-MIX-50G': [
      'assets/images/products/yog-timur-masala-chiura-mix-50g.webp',
      'assets/images/products/timur-masala-chiura-mix-alt.webp',
    ],
    'YUGA-BHUJIYA-10RS': [
      'assets/images/products/yuga-bhujiya-10rs.webp',
      'assets/images/products/yuga-snacks-range.webp',
    ],
    'YUGA-ROASTED-PEANUTS-10RS': [
      'assets/images/products/yuga-roasted-peanuts-10rs.webp',
      'assets/images/products/yuga-snacks-range.webp',
    ],
  };

  static const _aliases = <String, String>{
    'SAANJH-KALA-CHANA-WHOLE-1KG': 'SAANJH-WHOLE-CHANA-1KG',
    'GHARCHAMAK-DISHWASH-LIQUID-500ML':
        'GHARCHAMAK-DISHWASH-LIQUID-LEMON-FRESH-500ML',
    'GHARCHAMAK-DISHWASH-500ML': 'GHARCHAMAK-DISHWASH-LIQUID-LEMON-FRESH-500ML',
    'GHARCHAMAK-FLOOR-CLEANER-500ML':
        'GHARCHAMAK-FLOOR-CLEANER-FRESH-HOME-500ML',
    'GHARCHAMAK-TOILET-CLEANER-500ML':
        'GHARCHAMAK-TOILET-CLEANER-POWER-CLEAN-500ML',
    'YOG-TIMUR-MASALA-CHIURA-MIX-50G': 'TIMUR-MASALA-CHIURA-MIX-50G',
    'PAHAD-TIMUR-MASALA-CHIURA-MIX-50G': 'TIMUR-MASALA-CHIURA-MIX-50G',
  };

  static List<String> allForSku(String? sku) {
    if (sku == null || sku.trim().isEmpty) return const [];
    var normalized = sku
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[_\s]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    if (normalized.startsWith('DEMO-')) {
      normalized = normalized.substring('DEMO-'.length);
    }
    normalized = _aliases[normalized] ?? normalized;
    return _bySku[normalized] ?? const [];
  }

  static String? forSku(String? sku) {
    final images = allForSku(sku);
    return images.isEmpty ? null : images.first;
  }

  static String imageFor(Product product) =>
      forSku(product.sku) ?? product.imageUrl;
}
