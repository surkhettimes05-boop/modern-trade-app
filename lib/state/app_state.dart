import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models/models.dart';

const _fallbackProducts = <Product>[
  Product(
    id: 'opening-rice-5kg',
    sku: 'RICE-5KG',
    name: 'Premium Basmati Rice 5kg',
    brand: 'StoreSync Select',
    category: 'Rice',
    categoryId: 'opening-1',
    description: 'Long-grain premium rice for everyday family meals.',
    imageUrl:
        'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=900&q=82',
    price: 799,
    originalPrice: 999,
    rating: 4.8,
    reviewCount: 42,
    availability: 'AVAILABLE',
    unit: '5 kg bag',
  ),
  Product(
    id: 'opening-oil-1l',
    sku: 'OIL-1L',
    name: 'Sunflower Oil 1L',
    brand: 'StoreSync Select',
    category: 'Cooking oil & ghee',
    categoryId: 'opening-2',
    description: 'Refined sunflower oil for daily cooking.',
    imageUrl:
        'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=900&q=82',
    price: 179,
    originalPrice: 219,
    rating: 4.7,
    reviewCount: 35,
    availability: 'AVAILABLE',
    unit: '1 L bottle',
  ),
  Product(
    id: 'opening-water-1l',
    sku: 'WATER-1L',
    name: 'Mineral Water 1L',
    brand: 'StoreSync Select',
    category: 'Water',
    categoryId: 'opening-3',
    description: 'Purified mineral water for home and on-the-go.',
    imageUrl:
        'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?auto=format&fit=crop&w=900&q=82',
    price: 25,
    originalPrice: 30,
    rating: 4.6,
    reviewCount: 28,
    availability: 'AVAILABLE',
    unit: '1 L bottle',
  ),
  Product(
    id: 'opening-noodles',
    sku: 'NOODLES-FAM',
    name: 'Instant Noodles Family Pack',
    brand: 'Wai Wai',
    category: 'Instant noodles',
    categoryId: 'opening-4',
    description: 'Fast, familiar pantry comfort for busy days.',
    imageUrl:
        'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=82',
    price: 120,
    rating: 4.7,
    reviewCount: 31,
    availability: 'AVAILABLE',
    unit: '5 x 70 g',
  ),
  Product(
    id: 'opening-detergent',
    sku: 'LAUNDRY-1KG',
    name: 'Everyday Laundry Detergent 1kg',
    brand: 'StoreSync Select',
    category: 'Laundry',
    categoryId: 'opening-5',
    description: 'Reliable cleaning power for everyday laundry.',
    imageUrl:
        'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?auto=format&fit=crop&w=900&q=82',
    price: 245,
    rating: 4.5,
    reviewCount: 24,
    availability: 'AVAILABLE',
    unit: '1 kg pack',
  ),
  Product(
    id: 'opening-shampoo',
    sku: 'SHAMPOO-340',
    name: 'Daily Care Shampoo 340ml',
    brand: 'StoreSync Select',
    category: 'Hair care',
    categoryId: 'opening-6',
    description: 'Gentle everyday shampoo for the whole household.',
    imageUrl:
        'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=900&q=82',
    price: 299,
    rating: 4.4,
    reviewCount: 19,
    availability: 'AVAILABLE',
    unit: '340 ml bottle',
  ),
];

class AppState extends ChangeNotifier {
  AppState({ApiClient? api})
      : api = api ??
            ApiClient(
              baseUrl: const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'http://10.0.2.2:3001',
              ),
            );

  final ApiClient api;
  List<Product> products = const [];
  List<ProductCategory> categories = const [];
  List<StoreLocation> stores = const [];
  final Map<String, int> _cartQuantities = {};
  StoreLocation? selectedStore;
  Customer? customer;
  bool loading = true;
  bool usingFallbackCatalog = false;
  String? error;

  List<CartLine> get cart => _cartQuantities.entries
      .map((entry) {
        final product =
            products.where((item) => item.id == entry.key).firstOrNull;
        return product == null
            ? null
            : CartLine(product: product, quantity: entry.value);
      })
      .whereType<CartLine>()
      .toList(growable: false);

  int get cartCount =>
      _cartQuantities.values.fold(0, (sum, quantity) => sum + quantity);
  double get cartSubtotal => cart.fold(
        0,
        (sum, line) => sum + line.product.price * line.quantity,
      );
  bool get isSignedIn => customer != null;

  Future<void> initialize() async {
    loading = true;
    notifyListeners();
    try {
      await api.restoreSession();
      final prefs = await SharedPreferences.getInstance();
      final savedCart = prefs.getString('cart_v1');
      if (savedCart != null) {
        final decoded = jsonDecode(savedCart);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final quantity = int.tryParse(entry.value.toString());
            if (quantity != null && quantity > 0) {
              _cartQuantities[entry.key.toString()] = quantity;
            }
          }
        }
      }
      await loadCatalog();
      final savedStore = prefs.getString('selected_store');
      selectedStore =
          stores.where((store) => store.id == savedStore).firstOrNull ??
              stores.firstOrNull;
      if (api.hasSession) await validateSession();
    } catch (exception) {
      error = exception.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCatalog() async {
    error = null;
    try {
      final responses = await Future.wait([
        api.get('/api/public/products'),
        api.get('/api/public/categories'),
        api.get('/api/public/stores'),
      ]);
      products = _mapList(responses[0], Product.fromJson)
          .where((product) => product.price > 0)
          .toList(growable: false);
      categories = _mapList(responses[1], ProductCategory.fromJson);
      stores = _mapList(responses[2], StoreLocation.fromJson);
      if (products.isEmpty) throw const ApiException('Catalog is empty');
      usingFallbackCatalog = false;
    } catch (exception) {
      products = _fallbackProducts;
      categories = _fallbackCategories;
      stores = const [
        StoreLocation(
          id: 'offline-store',
          name: 'NOVA MART',
          address: 'Connect to the StoreSync API for live availability',
        ),
      ];
      usingFallbackCatalog = true;
      error = 'Live catalog unavailable. Showing the opening range.';
    }
    notifyListeners();
  }

  List<T> _mapList<T>(dynamic value, T Function(Map<String, dynamic>) mapper) {
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

  List<Product> search(String query, {String? categoryId}) {
    final normalized = query.trim().toLowerCase();
    return products.where((product) {
      final categoryMatch = categoryId == null ||
          product.categoryId == categoryId ||
          product.category.toLowerCase() == categoryId.toLowerCase();
      final textMatch = normalized.isEmpty ||
          '${product.name} ${product.brand} ${product.category}'
              .toLowerCase()
              .contains(normalized);
      return categoryMatch && textMatch;
    }).toList(growable: false);
  }

  Future<void> selectStore(StoreLocation store) async {
    selectedStore = store;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_store', store.id);
    notifyListeners();
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    _cartQuantities.update(
      product.id,
      (current) => current + quantity,
      ifAbsent: () => quantity,
    );
    await _saveCart();
    notifyListeners();
  }

  Future<void> setCartQuantity(Product product, int quantity) async {
    if (quantity <= 0) {
      _cartQuantities.remove(product.id);
    } else {
      _cartQuantities[product.id] = quantity;
    }
    await _saveCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _cartQuantities.clear();
    await _saveCart();
    notifyListeners();
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart_v1', jsonEncode(_cartQuantities));
  }

  Future<String?> requestOtp(String phone) async {
    final response = await api.post(
      '/api/auth/otp/request',
      body: {'phone': phone, 'purpose': 'LOGIN'},
    );
    return response is Map ? response['otp']?.toString() : null;
  }

  Future<void> verifyOtp(String phone, String code) async {
    final response = await api.post(
      '/api/auth/otp/verify',
      body: {'phone': phone, 'otp_code': code, 'purpose': 'LOGIN'},
    );
    if (response is! Map || response['customer'] is! Map) {
      throw const ApiException('The login response did not contain a customer');
    }
    customer = Customer.fromJson(
      Map<String, dynamic>.from(response['customer'] as Map),
    );
    notifyListeners();
  }

  Future<void> validateSession() async {
    try {
      final response = await api.get('/api/auth/session/validate');
      if (response is Map && response['customer'] is Map) {
        customer = Customer.fromJson(
          Map<String, dynamic>.from(response['customer'] as Map),
        );
      }
    } on ApiException catch (exception) {
      if (exception.statusCode == 401) await api.clearSession();
      customer = null;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.post('/api/auth/logout');
    } finally {
      await api.clearSession();
      customer = null;
      notifyListeners();
    }
  }

  Future<List<CustomerOrder>> loadOrders() async {
    final response = await api.get('/api/customer/orders');
    return _mapList(response, CustomerOrder.fromJson);
  }

  Future<CustomerOrder> checkout({
    required String deliveryType,
    required String name,
    required String phone,
    required String address,
    required String city,
    required String state,
    required String postalCode,
    String? notes,
  }) async {
    final store = selectedStore;
    if (store == null || store.id == 'offline-store') {
      throw const ApiException('Choose a live store before checkout');
    }
    if (cart.isEmpty) throw const ApiException('Your cart is empty');
    final cartResponse = await api.post(
      '/api/shopping-cart',
      body: {'store_id': store.id},
    );
    final cartId = cartResponse is Map ? cartResponse['id']?.toString() : null;
    if (cartId == null) throw const ApiException('Could not create cart');
    for (final line in cart) {
      await api.post(
        '/api/shopping-cart/$cartId/items',
        body: {'product_id': line.product.id, 'quantity': line.quantity},
      );
    }
    final result = await api.post(
      '/api/checkout/cod',
      body: {
        'cart_id': cartId,
        'store_id': store.id,
        'idempotency_key':
            'mobile-${DateTime.now().microsecondsSinceEpoch}-${customer!.id}',
        'delivery_type': deliveryType,
        'shipping_name': name,
        'shipping_phone': phone,
        'shipping_address': address,
        'shipping_city': city,
        'shipping_state': state,
        'shipping_postal_code': postalCode,
        'shipping_country': 'NP',
        if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
      },
    );
    if (result is! Map) throw const ApiException('Invalid order response');
    final order = CustomerOrder.fromJson(Map<String, dynamic>.from(result));
    await clearCart();
    return order;
  }

  @override
  void dispose() {
    api.close();
    super.dispose();
  }
}

const _fallbackCategories = <ProductCategory>[
  ProductCategory(id: 'opening-1', name: 'Rice', slug: 'rice', skuCount: 25),
  ProductCategory(
    id: 'opening-2',
    name: 'Cooking oil & ghee',
    slug: 'cooking-oil-ghee',
    skuCount: 25,
  ),
  ProductCategory(id: 'opening-3', name: 'Water', slug: 'water', skuCount: 8),
  ProductCategory(
    id: 'opening-4',
    name: 'Instant noodles',
    slug: 'instant-noodles',
    skuCount: 25,
  ),
  ProductCategory(
      id: 'opening-5', name: 'Laundry', slug: 'laundry', skuCount: 25),
  ProductCategory(
      id: 'opening-6', name: 'Hair care', slug: 'hair-care', skuCount: 25),
];

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
