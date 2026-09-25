import '../core/api_client.dart';
import '../models/models.dart';

class CatalogData {
  const CatalogData(this.products, this.categories, this.stores);
  final List<Product> products;
  final List<ProductCategory> categories;
  final List<StoreLocation> stores;
}

class CatalogRepository {
  CatalogRepository(this.api);
  final ApiClient api;

  Future<List<StoreLocation>> loadStores() async =>
      mapList(await api.get('/api/public/stores'), StoreLocation.fromJson);

  Future<CatalogData> loadForStore(
      String storeId, List<StoreLocation> stores) async {
    if (storeId.isEmpty) {
      throw const ApiException('Choose a store to view its catalog.');
    }
    final responses = await Future.wait([
      api.get('/api/public/products', query: {'store_id': storeId}),
      api.get('/api/public/categories'),
    ]);
    final products = mapList(responses[0], Product.fromJson)
        .where((p) => p.id.isNotEmpty && p.priceMinor > 0)
        .toList(growable: false);
    if (products.isEmpty) {
      throw const ApiException('No products are available for this store.',
          kind: ApiErrorKind.invalidResponse);
    }
    return CatalogData(
        products, mapList(responses[1], ProductCategory.fromJson), stores);
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
