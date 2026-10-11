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
    required this.storeId,
    required this.municipalityId,
    required this.wardId,
    this.address = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.notes,
  });
  final String deliveryType;
  final String name;
  final String phone;
  final String storeId;
  final int municipalityId;
  final int wardId;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String? notes;
}

class DeliveryWard {
  const DeliveryWard({
    required this.id,
    required this.wardNumber,
    required this.name,
  });
  final int id;
  final int wardNumber;
  final String name;

  factory DeliveryWard.fromJson(Map<String, dynamic> json) => DeliveryWard(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        wardNumber: int.tryParse(json['ward_number']?.toString() ?? '') ?? 0,
        name: json['name_en']?.toString() ??
            'Ward ${json['ward_number']?.toString() ?? ''}',
      );
}

class DeliveryServiceArea {
  const DeliveryServiceArea({
    required this.id,
    required this.name,
    required this.wards,
  });
  final int id;
  final String name;
  final List<DeliveryWard> wards;

  factory DeliveryServiceArea.fromJson(Map<String, dynamic> json) {
    final rawWards = json['wards'];
    return DeliveryServiceArea(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name_en']?.toString() ?? 'Service area',
      wards: rawWards is List
          ? rawWards
              .whereType<Map>()
              .map((row) =>
                  DeliveryWard.fromJson(Map<String, dynamic>.from(row)))
              .where((ward) => ward.id > 0)
              .toList(growable: false)
          : const [],
    );
  }
}

class DeliveryQuote {
  const DeliveryQuote({
    required this.fee,
    required this.estimatedHours,
    this.zoneName,
  });
  final double fee;
  final int estimatedHours;
  final String? zoneName;

  factory DeliveryQuote.fromJson(Map<String, dynamic> json) => DeliveryQuote(
        fee: double.tryParse(json['delivery_fee']?.toString() ?? '') ?? 0,
        estimatedHours:
            int.tryParse(json['estimated_delivery_hours']?.toString() ?? '') ??
                0,
        zoneName: json['zone_name']?.toString(),
      );
}

class CheckoutRepository {
  CheckoutRepository(this.api, {Random? random})
      : _random = random ?? Random.secure();
  final ApiClient api;
  final Random _random;
  static const _attemptKey = 'checkout_attempt_v1';

  Future<List<StoreLocation>> loadStores() async {
    final response = await api.get('/api/public/stores');
    final rows = response is List ? response : const [];
    return rows
        .whereType<Map>()
        .map((row) => StoreLocation.fromJson(Map<String, dynamic>.from(row)))
        .where((store) => store.id.isNotEmpty && !store.temporarilyClosed)
        .toList(growable: false);
  }

  Future<List<DeliveryServiceArea>> loadServiceAreas(String storeId) async {
    final response = await api.get('/api/checkout/service-areas',
        query: {'store_id': storeId});
    final rows = response is List ? response : const [];
    return rows
        .whereType<Map>()
        .map((row) =>
            DeliveryServiceArea.fromJson(Map<String, dynamic>.from(row)))
        .where((area) => area.id > 0 && area.wards.isNotEmpty)
        .toList(growable: false);
  }

  Future<DeliveryQuote> loadDeliveryQuote({
    required String storeId,
    required int municipalityId,
    required int wardId,
    required double orderValue,
  }) async {
    final response = await api.post('/api/checkout/delivery-quote', body: {
      'store_id': storeId,
      'municipality_id': municipalityId,
      'ward_id': wardId,
      'order_value': orderValue,
    });
    if (response is! Map || response['serviceable'] != true) {
      throw const ApiException('This address is not currently serviceable.');
    }
    return DeliveryQuote.fromJson(Map<String, dynamic>.from(response));
  }

  Future<CustomerOrder> checkout(
      {required Customer customer,
      required List<CartLine> lines,
      required CheckoutDetails details}) async {
    if (lines.isEmpty) throw const ApiException('Your cart is empty');
    if (details.deliveryType != 'DELIVERY') {
      throw const ApiException('Only central-warehouse delivery is available.');
    }
    for (final line in lines) {
      if (!line.product.canOrder ||
          line.quantity < 1 ||
          line.quantity > AppConfig.maxCartQuantity) {
        throw const ApiException(
            'One or more cart quantities are invalid. Please review your cart.');
      }
    }
    final fingerprint = _fingerprint(customer.id, lines, details);
    final prefs = await SharedPreferences.getInstance();
    var attempt = _Attempt.read(prefs.getString(_attemptKey));
    if (attempt == null || attempt.fingerprint != fingerprint) {
      attempt = _Attempt(key: _newKey(customer.id), fingerprint: fingerprint);
      await _save(prefs, attempt);
    }
    var activeAttempt = attempt;

    if (activeAttempt.cartId == null) {
      final response = await api.post('/api/shopping-cart', body: const {});
      final cartId = response is Map ? response['id']?.toString() : null;
      if (cartId == null || cartId.isEmpty) {
        throw const ApiException(
            'Could not prepare your cart. Please try again.',
            kind: ApiErrorKind.invalidResponse);
      }
      activeAttempt = activeAttempt.copyWith(cartId: cartId);
      await _save(prefs, activeAttempt);
    }

    for (final line in lines) {
      if (activeAttempt.uploadedProductIds.contains(line.product.id)) continue;
      await api.post('/api/shopping-cart/${activeAttempt.cartId}/items',
          body: {'product_id': line.product.id, 'quantity': line.quantity});
      activeAttempt = activeAttempt.copyWith(uploadedProductIds: {
        ...activeAttempt.uploadedProductIds,
        line.product.id
      });
      await _save(prefs, activeAttempt);
    }

    final delivery = details.deliveryType == 'DELIVERY';
    final result = await api.post('/api/checkout/cod', body: {
      'cart_id': activeAttempt.cartId,
      'store_id': details.storeId,
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
    });
    if (result is! Map) {
      throw const ApiException(
          'The order response was invalid. Please retry to safely confirm the order.',
          kind: ApiErrorKind.invalidResponse);
    }
    final order = CustomerOrder.fromJson(Map<String, dynamic>.from(result));
    if (order.id.isEmpty) {
      throw const ApiException(
          'The order could not be confirmed. Please retry safely.',
          kind: ApiErrorKind.invalidResponse);
    }
    await prefs.remove(_attemptKey);
    return order;
  }

  Future<void> abandonAttempt() async =>
      (await SharedPreferences.getInstance()).remove(_attemptKey);
  Future<void> _save(SharedPreferences prefs, _Attempt attempt) =>
      prefs.setString(_attemptKey, jsonEncode(attempt.toJson()));
  String _newKey(String customerId) =>
      'mobile-$customerId-${DateTime.now().microsecondsSinceEpoch}-${List.generate(12, (_) => _random.nextInt(16).toRadixString(16)).join()}';
  String _fingerprint(
      String customerId, List<CartLine> lines, CheckoutDetails details) {
    final entries = lines
        .map((line) => '${line.product.id}:${line.quantity}')
        .toList()
      ..sort();
    return [
      customerId,
      entries.join(','),
      details.deliveryType,
      details.storeId,
      details.municipalityId.toString(),
      details.wardId.toString(),
      details.name.trim(),
      details.phone.trim(),
      details.address.trim(),
      details.city.trim(),
      details.state.trim(),
      details.postalCode.trim(),
      details.notes?.trim() ?? '',
    ].join('|');
  }
}

class _Attempt {
  const _Attempt(
      {required this.key,
      required this.fingerprint,
      this.cartId,
      this.uploadedProductIds = const {}});
  final String key;
  final String fingerprint;
  final String? cartId;
  final Set<String> uploadedProductIds;
  _Attempt copyWith({String? cartId, Set<String>? uploadedProductIds}) =>
      _Attempt(
          key: key,
          fingerprint: fingerprint,
          cartId: cartId ?? this.cartId,
          uploadedProductIds: uploadedProductIds ?? this.uploadedProductIds);
  Map<String, dynamic> toJson() => {
        'key': key,
        'fingerprint': fingerprint,
        'cart_id': cartId,
        'uploaded': uploadedProductIds.toList()
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
                  .toSet());
    } on FormatException {
      return null;
    }
  }
}
