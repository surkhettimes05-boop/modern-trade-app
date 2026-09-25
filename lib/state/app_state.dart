import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/app_config.dart';
import '../models/models.dart';
import '../repositories/auth_repository.dart';
import '../repositories/cart_controller.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/checkout_repository.dart';
import '../repositories/customer_repository.dart';

class AppState extends ChangeNotifier {
  AppState({ApiClient? api})
      : _usesEnvironmentConfig = api == null,
        api = api ?? ApiClient(baseUrl: AppConfig.apiBaseUrl) {
    authRepository = AuthRepository(this.api);
    catalogRepository = CatalogRepository(this.api);
    checkoutRepository = CheckoutRepository(this.api);
    customerRepository = CustomerRepository(this.api);
    this.api.onSessionExpired = _onSessionExpired;
  }

  final ApiClient api;
  final bool _usesEnvironmentConfig;
  late final AuthRepository authRepository;
  late final CatalogRepository catalogRepository;
  late final CheckoutRepository checkoutRepository;
  late final CustomerRepository customerRepository;
  final CartController cartController = CartController();
  List<Product> products = const [];
  List<ProductCategory> categories = const [];
  List<StoreLocation> stores = const [];
  StoreLocation? selectedStore;
  Customer? customer;
  bool loading = true;
  bool catalogLoading = false;
  String? error;

  List<CartLine> get cart => cartController.quantities.entries
      .map((entry) {
        final product =
            products.where((item) => item.id == entry.key).firstOrNull;
        return product == null
            ? null
            : CartLine(product: product, quantity: entry.value);
      })
      .whereType<CartLine>()
      .toList(growable: false);

  int get cartCount => cartController.quantities.values
      .fold(0, (sum, quantity) => sum + quantity);
  int get cartSubtotalMinor =>
      cart.fold(0, (sum, line) => sum + line.totalMinor);
  double get cartSubtotal => cartSubtotalMinor / 100;
  bool get isSignedIn => customer != null;

  Future<void> initialize() async {
    loading = true;
    notifyListeners();
    try {
      if (_usesEnvironmentConfig) {
        final configurationError = AppConfig.configurationError();
        if (configurationError != null) throw ApiException(configurationError);
      }
      await api.restoreSession();
      try {
        stores = await catalogRepository.loadStores();
        if (stores.isEmpty) {
          throw const ApiException('No fulfilment stores are available.');
        }
        final prefs = await SharedPreferences.getInstance();
        final savedStore = prefs.getString('selected_store');
        selectedStore =
            stores.where((store) => store.id == savedStore).firstOrNull ??
                stores.where((store) => !store.temporarilyClosed).firstOrNull;
        if (selectedStore == null) {
          throw const ApiException('No fulfilment stores are currently open.');
        }
        await loadCatalog();
        await cartController.restore(products);
      } catch (exception) {
        products = const [];
        categories = const [];
        error = userMessage(exception);
      }
      if (api.hasSession) await validateSession();
    } catch (exception) {
      error = userMessage(exception);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCatalog({bool clearExisting = false}) async {
    error = null;
    catalogLoading = true;
    if (clearExisting) {
      products = const [];
      categories = const [];
    }
    notifyListeners();
    try {
      if (stores.isEmpty) stores = await catalogRepository.loadStores();
      selectedStore ??=
          stores.where((store) => !store.temporarilyClosed).firstOrNull;
      final store = selectedStore;
      if (store == null) {
        throw const ApiException('Choose a store to view products.');
      }
      final catalog = await catalogRepository.loadForStore(store.id, stores);
      products = catalog.products;
      categories = catalog.categories;
      stores = catalog.stores;
    } catch (exception) {
      if (clearExisting) {
        products = const [];
        categories = const [];
      }
      error = userMessage(exception);
    } finally {
      catalogLoading = false;
    }
    notifyListeners();
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
    if (store.id == selectedStore?.id) return;
    selectedStore = store;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_store', store.id);
    await checkoutRepository.abandonAttempt();
    await loadCatalog(clearExisting: true);
    await cartController.restore(products);
    notifyListeners();
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    await cartController.add(product, quantity: quantity);
    notifyListeners();
  }

  Future<void> setCartQuantity(Product product, int quantity) async {
    await cartController.set(product, quantity);
    notifyListeners();
  }

  Future<void> clearCart() async {
    await cartController.clear();
    await checkoutRepository.abandonAttempt();
    notifyListeners();
  }

  Future<void> requestOtp(String phone) => authRepository.requestOtp(phone);

  Future<void> verifyOtp(String phone, String code) async {
    customer = await authRepository.verifyOtp(phone, code);
    notifyListeners();
  }

  Future<void> validateSession() async {
    try {
      customer = await authRepository.validateSession();
    } on ApiException catch (exception) {
      if (exception.statusCode == 401) await api.clearSession();
      customer = null;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await authRepository.logout();
    } finally {
      customer = null;
      notifyListeners();
    }
  }

  Future<List<CustomerOrder>> loadOrders() => customerRepository.loadOrders();

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
    if (customer == null) {
      throw const ApiException('Please sign in to checkout.',
          kind: ApiErrorKind.authentication);
    }
    final store = selectedStore;
    if (store == null) {
      throw const ApiException('Choose a live store before checkout');
    }
    if (cart.isEmpty) throw const ApiException('Your cart is empty');
    try {
      final order = await checkoutRepository.checkout(
        store: store,
        customer: customer!,
        lines: cart,
        details: CheckoutDetails(
            deliveryType: deliveryType,
            name: name,
            phone: phone,
            address: address,
            city: city,
            state: state,
            postalCode: postalCode,
            notes: notes),
      );
      await clearCart();
      return order;
    } on ApiException catch (exception) {
      if (exception.kind == ApiErrorKind.conflict) {
        await loadCatalog();
        await cartController.restore(products);
        notifyListeners();
        throw const ApiException(
          'A price or availability changed. Your cart has been refreshed; please review it and try again.',
          kind: ApiErrorKind.conflict,
        );
      }
      rethrow;
    }
  }

  Future<void> _onSessionExpired() async {
    customer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    api.close();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
