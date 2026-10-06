import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/app_config.dart';
import '../models/models.dart';

class CheckoutDetails {
  const CheckoutDetails({
    required this.deliveryType,
    required this.name,
    required this.phone,
    this.address = '',
    this.municipalityId,
    this.wardId,
    this.postalCode = '',
    this.notes,
  });
  final String deliveryType;
  final String name;
  final String phone;
  final String address;
  final int? municipalityId;
  final int? wardId;
  final String postalCode;
  final String? notes;
}

class CheckoutRepository {
  CheckoutRepository(this.api, {Random? random})
    : _random = random ?? Random.secure();
  final ApiClient api;
  final Random _random;
  static const _attemptKey = 'checkout_attempt_v2';

  Future<CustomerOrder> checkout({
    required StoreLocation store,
    required Customer customer,
    required List<CartLine> lines,
    required CheckoutDetails details,
  }) async {
    if (lines.isEmpty) throw const ApiException('Your cart is empty');
    if (details.deliveryType != 'PICKUP' &&
        details.deliveryType != 'DELIVERY') {
      throw const ApiException('Choose delivery or pickup.');
    }
    if (details.deliveryType == 'DELIVERY' &&
        (details.municipalityId == null || details.wardId == null)) {
      throw const ApiException('Choose a serviceable municipality and ward.');
    }
    for (final line in lines) {
      if (!line.product.isAvailable ||
          line.quantity < 1 ||
          line.quantity > AppConfig.maxCartQuantity) {
        throw const ApiException(
          'One or more cart quantities are invalid. Please review your cart.',
        );
      }
    }
    final fingerprint = _fingerprint(store.id, customer.id, lines);
    final prefs = await SharedPreferences.getInstance();
    var attempt = _Attempt.read(prefs.getString(_attemptKey));
    if (attempt == null || attempt.fingerprint != fingerprint) {
      attempt = _Attempt(key: _newKey(customer.id), fingerprint: fingerprint);
      await _save(prefs, attempt);
    }
    var activeAttempt = attempt;

    if (activeAttempt.cartId == null) {
      final response = await api.post(
        '/api/shopping-cart',
        body: {'store_id': store.id},
      );
      final cartId = response is Map ? response['id']?.toString() : null;
      if (cartId == null || cartId.isEmpty) {
        throw const ApiException(
          'Could not prepare your cart. Please try again.',
          kind: ApiErrorKind.invalidResponse,
        );
      }
      activeAttempt = activeAttempt.copyWith(cartId: cartId);
      await _save(prefs, activeAttempt);
    }

    if (activeAttempt.uploadedProductIds.isEmpty) {
      await api.put(
        '/api/shopping-cart/${activeAttempt.cartId}/items',
        body: {
          'items': lines
              .map(
                (line) => {
                  'product_id': line.product.id,
                  'quantity': line.quantity,
                },
              )
              .toList(),
        },
      );
      activeAttempt = activeAttempt.copyWith(
        uploadedProductIds: {...lines.map((line) => line.product.id)},
      );
      await _save(prefs, activeAttempt);
    }

    final delivery = details.deliveryType == 'DELIVERY';
    final result = await api.post(
      '/api/checkout/cod',
      body: {
        'cart_id': activeAttempt.cartId,
        'store_id': store.id,
        'idempotency_key': activeAttempt.key,
        'delivery_type': details.deliveryType,
        'shipping_name': details.name,
        'shipping_phone': details.phone,
        if (delivery) 'shipping_address': details.address,
        if (delivery) 'shipping_municipality_id': details.municipalityId,
        if (delivery) 'shipping_ward_id': details.wardId,
        if (delivery) 'shipping_postal_code': details.postalCode,
        if (delivery) 'shipping_country': 'NP',
        if (details.notes?.trim().isNotEmpty == true)
          'notes': details.notes!.trim(),
      },
    );
    if (result is! Map) {
      throw const ApiException(
        'The order response was invalid. Please retry to safely confirm the order.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
    final order = CustomerOrder.fromJson(Map<String, dynamic>.from(result));
    if (order.id.isEmpty) {
      throw const ApiException(
        'The order could not be confirmed. Please retry safely.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
    await prefs.remove(_attemptKey);
    return order;
  }

  Future<List<Map<String, dynamic>>> deliveryAreas(String storeId) async {
    final result = await api.get(
      '/api/checkout/service-areas',
      query: {'store_id': storeId},
    );
    if (result is! List)
      throw const ApiException('Could not load delivery areas.');
    return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> deliveryQuote(
    String storeId,
    int municipalityId,
    int wardId,
    double subtotal,
  ) async {
    final result = await api.post(
      '/api/checkout/delivery-quote',
      body: {
        'store_id': storeId,
        'municipality_id': municipalityId,
        'ward_id': wardId,
        'order_value': subtotal,
      },
    );
    if (result is! Map) throw const ApiException('Could not quote delivery.');
    return Map<String, dynamic>.from(result);
  }

  Future<void> abandonAttempt() async =>
      (await SharedPreferences.getInstance()).remove(_attemptKey);
  Future<void> _save(SharedPreferences prefs, _Attempt attempt) =>
      prefs.setString(_attemptKey, jsonEncode(attempt.toJson()));
  String _newKey(String customerId) =>
      'mobile-$customerId-${DateTime.now().microsecondsSinceEpoch}-${List.generate(12, (_) => _random.nextInt(16).toRadixString(16)).join()}';
  String _fingerprint(String storeId, String customerId, List<CartLine> lines) {
    final entries =
        lines.map((line) => '${line.product.id}:${line.quantity}').toList()
          ..sort();
    return '$storeId|$customerId|${entries.join(',')}';
  }
}

class _Attempt {
  const _Attempt({
    required this.key,
    required this.fingerprint,
    this.cartId,
    this.uploadedProductIds = const {},
  });
  final String key;
  final String fingerprint;
  final String? cartId;
  final Set<String> uploadedProductIds;
  _Attempt copyWith({String? cartId, Set<String>? uploadedProductIds}) =>
      _Attempt(
        key: key,
        fingerprint: fingerprint,
        cartId: cartId ?? this.cartId,
        uploadedProductIds: uploadedProductIds ?? this.uploadedProductIds,
      );
  Map<String, dynamic> toJson() => {
    'key': key,
    'fingerprint': fingerprint,
    'cart_id': cartId,
    'uploaded': uploadedProductIds.toList(),
  };
  static _Attempt? read(String? raw) {
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map || map['key'] == null || map['fingerprint'] == null) {
        return null;
      }
      return _Attempt(
        key: map['key'].toString(),
        fingerprint: map['fingerprint'].toString(),
        cartId: map['cart_id']?.toString(),
        uploadedProductIds:
            (map['uploaded'] is List ? map['uploaded'] as List : const [])
                .map((e) => e.toString())
                .toSet(),
      );
    } on FormatException {
      return null;
    }
  }
}
