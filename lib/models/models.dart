import 'package:intl/intl.dart';

double _number(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

String _text(Object? value, [String fallback = '']) =>
    value?.toString() ?? fallback;

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.availability,
    this.sku,
    this.categoryId,
    this.originalPrice,
    this.rating = 0,
    this.reviewCount = 0,
    this.unit,
    this.createdAt,
    this.featured = false,
  });

  final String id;
  final String? sku;
  final String name;
  final String brand;
  final String category;
  final String? categoryId;
  final String description;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final String availability;
  final String? unit;
  final DateTime? createdAt;
  final bool featured;

  /// Known sellable states remain available while unknown states fail closed.
  bool get isAvailable =>
      const {'AVAILABLE', 'LOW_STOCK'}.contains(availability.trim().toUpperCase());
  int get priceMinor => (price * 100).round();
  int? get originalPriceMinor =>
      originalPrice == null ? null : (originalPrice! * 100).round();
  int get discountPercent => originalPrice == null || originalPrice! <= price
      ? 0
      : ((1 - price / originalPrice!) * 100).round();

  factory Product.fromJson(Map<String, dynamic> json) {
    final images = json['images'];
    final firstImage =
        images is List && images.isNotEmpty ? images.first : null;
    return Product(
      id: _text(json['id']),
      sku: json['sku']?.toString(),
      name: _text(json['name'], 'Product'),
      brand: _text(json['brand'], 'Unbranded'),
      category: _text(json['category_name'], 'Everyday essentials'),
      categoryId: json['category_id']?.toString(),
      description: _text(json['description']),
      imageUrl: _text(json['image_url'] ?? firstImage),
      price: _number(json['price']),
      originalPrice: json['original_price'] == null
          ? null
          : _number(json['original_price']),
      rating: _number(json['rating']),
      reviewCount: int.tryParse(_text(json['review_count'], '0')) ?? 0,
      availability: _text(json['availability_status'], 'OUT_OF_STOCK'),
      unit: json['unit']?.toString() ?? json['pack_size']?.toString(),
      createdAt: DateTime.tryParse(_text(json['created_at'])),
      featured: json['is_featured'] == true,
    );
  }
}

class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.description,
    this.skuCount = 0,
  });

  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String? description;
  final int skuCount;

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        id: _text(json['id']),
        name: _text(json['name'], 'Category'),
        slug: _text(json['slug']),
        imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
        description: json['description']?.toString(),
        skuCount: int.tryParse(_text(json['sku_count'], '0')) ?? 0,
      );
}

class StorefrontOffer {
  const StorefrontOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
    this.bannerImageUrl,
    this.featured = false,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? bannerImageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final bool featured;
  final int sortOrder;

  String? get displayImage {
    final banner = bannerImageUrl?.trim();
    if (banner != null && banner.isNotEmpty) return banner;
    final image = imageUrl?.trim();
    return image == null || image.isEmpty ? null : image;
  }

  factory StorefrontOffer.fromJson(Map<String, dynamic> json) => StorefrontOffer(
        id: _text(json['id']),
        title: _text(json['title'], 'Pasalho promotion'),
        description: _text(json['description']),
        imageUrl: json['image_url']?.toString(),
        bannerImageUrl: json['banner_image_url']?.toString(),
        startDate: DateTime.tryParse(_text(json['start_date'])) ?? DateTime.now(),
        endDate: DateTime.tryParse(_text(json['end_date'])) ??
            DateTime.now().add(const Duration(days: 1)),
        featured: json['is_featured'] == true,
        sortOrder: int.tryParse(_text(json['sort_order'], '0')) ?? 0,
      );
}

class StoreLocation {
  const StoreLocation({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.hours,
    this.temporarilyClosed = false,
  });

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? hours;
  final bool temporarilyClosed;

  factory StoreLocation.fromJson(Map<String, dynamic> json) => StoreLocation(
        id: _text(json['id']),
        name: _text(json['name'], 'Pasalho'),
        address: json['address']?.toString(),
        phone: json['phone']?.toString(),
        hours: json['hours']?.toString(),
        temporarilyClosed: json['is_temporarily_closed'] == true,
      );
}

class CartLine {
  const CartLine({required this.product, required this.quantity});
  final Product product;
  final int quantity;
  int get totalMinor => product.priceMinor * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);

  Map<String, dynamic> toJson() => {
        'product_id': product.id,
        'quantity': quantity,
      };
}

class Customer {
  const Customer({
    required this.id,
    this.phoneMasked,
    this.preferredName,
    this.email,
    this.verificationStatus,
  });
  final String id;
  final String? phoneMasked;
  final String? preferredName;
  final String? email;
  final String? verificationStatus;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: _text(json['id']),
        phoneMasked: json['phone_masked']?.toString(),
        preferredName: json['preferred_name']?.toString(),
        email: json['email']?.toString(),
        verificationStatus: json['verification_status']?.toString(),
      );
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.status,
    required this.total,
    this.orderNumber,
    this.orderDate,
    this.deliveryType,
  });
  final String id;
  final String? orderNumber;
  final String status;
  final double total;
  int get totalMinor => (total * 100).round();
  final DateTime? orderDate;
  final String? deliveryType;

  factory CustomerOrder.fromJson(Map<String, dynamic> json) => CustomerOrder(
        id: _text(json['id']),
        orderNumber: json['order_number']?.toString(),
        status: _text(json['status'], 'PENDING'),
        total: _number(
            json['total_amount'] ?? json['grand_total'] ?? json['total']),
        orderDate:
            DateTime.tryParse(_text(json['order_date'] ?? json['created_at'])),
        deliveryType: json['delivery_type']?.toString(),
      );
}

String formatNpr(num value) => formatNprMinor((value * 100).round());

String formatNprMinor(int minorUnits) {
  return 'NPR ${NumberFormat('#,##0.##', 'en_US').format(minorUnits / 100)}';
}
