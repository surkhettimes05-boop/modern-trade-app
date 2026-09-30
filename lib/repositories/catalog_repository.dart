import '../core/api_client.dart';
import '../models/models.dart';

class CatalogData {
  const CatalogData(this.products, this.categories);
  final List<Product> products;
  final List<ProductCategory> categories;
}

class CatalogRepository {
  CatalogRepository(this.api);
  final ApiClient api;

  Future<CatalogData> load() async {
    final responses = await Future.wait([
      api.get('/api/public/products'),
      api.get('/api/public/categories'),
    ]);
    final products = mapList(responses[0], Product.fromJson)
        .where((p) => p.id.isNotEmpty && p.priceMinor > 0)
        .toList(growable: false);
    if (products.isEmpty) {
      throw const ApiException('No products are currently available.',
          kind: ApiErrorKind.invalidResponse);
    }
    return CatalogData(products, mapList(responses[1], ProductCategory.fromJson));
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
