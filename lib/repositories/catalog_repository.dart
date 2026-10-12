import '../core/api_client.dart';
import '../models/models.dart';

class CatalogData {
  const CatalogData(
    this.products,
    this.categories,
    this.stores,
    this.offers,
    this.campaigns,
  );
  final List<Product> products;
  final List<ProductCategory> categories;
  final List<StoreLocation> stores;
  final List<StorefrontOffer> offers;
  final List<Campaign> campaigns;
}

class CatalogRepository {
  CatalogRepository(this.api);
  final ApiClient api;

  Future<CatalogData> load() async {
    final responses = await Future.wait([
      api.get('/api/public/products?limit=2500'),
      api.get('/api/public/categories'),
      api.get('/api/public/stores'),
      api.get('/api/public/offers'),
    ]);
    final products = mapList(responses[0], Product.fromJson)
        .where((product) => product.priceMinor > 0)
        .toList(growable: false);
    if (products.isEmpty) {
      throw const ApiException(
        'Catalog is empty',
        kind: ApiErrorKind.invalidResponse,
      );
    }

    List<Campaign> campaigns = const [];
    try {
      final response = await api.get(
        '/api/public/campaigns',
        query: const {'channel': 'APP'},
      );
      campaigns = mapList(response, Campaign.fromJson);
    } on ApiException {
      // Marketing content is optional and must not take the live catalog down.
      campaigns = const [];
    }

    return CatalogData(
      products,
      mapList(responses[1], ProductCategory.fromJson),
      mapList(responses[2], StoreLocation.fromJson),
      mapList(responses[3], StorefrontOffer.fromJson),
      campaigns,
    );
  }
}

List<T> mapList<T>(dynamic value, T Function(Map<String, dynamic>) mapper) {
  final rows = value is List
      ? value
      : value is Map && value['data'] is List
          ? value['data'] as List
          : const [];
  return rows
      .whereType<Map>()
      .map((row) => mapper(Map<String, dynamic>.from(row)))
      .toList(growable: false);
}
