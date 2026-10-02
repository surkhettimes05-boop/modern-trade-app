import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../demo/demo_product_assets.dart';
import '../main.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'cart_screen.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key, required this.product});
  final Product product;
  void _basket(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Your basket')),
              body: CartScreen(onShop: () => Navigator.pop(context)))));
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final quantity = state.cartController.quantities[product.id] ?? 0;
    final related =
        state.products.where((p) => p.id != product.id).take(6).toList();
    return Scaffold(
        appBar: AppBar(
            title: Text(product.category,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                  tooltip: 'View basket',
                  onPressed: () => _basket(context),
                  icon: Badge(
                      isLabelVisible: state.cartCount > 0,
                      label: Text('${state.cartCount}'),
                      child: const Icon(Icons.shopping_bag_outlined)))
            ]),
        body: ScreenFrame(
            maxWidth: 760,
            child:
                ListView(padding: const EdgeInsets.only(bottom: 24), children: [
              Container(
                  color: Colors.white,
                  height: 300,
                  padding: const EdgeInsets.all(35),
                  child:
                      ProductImage(url: DemoProductAssets.imageFor(product))),
              Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            product.brand.isEmpty
                                ? 'EVERYDAY ESSENTIAL'
                                : product.brand.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 1,
                                color: AppColors.brand,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 9),
                        Text(product.name,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.7,
                                height: 1.15)),
                        const SizedBox(height: 9),
                        Text(product.unit ?? 'Standard pack',
                            style: const TextStyle(color: AppColors.muted)),
                        if (product.rating > 0 && product.reviewCount > 0) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.star,
                                color: AppColors.brand, size: 16),
                            Text(
                                ' ${product.rating.toStringAsFixed(1)} · ${product.reviewCount} reviews',
                                style: const TextStyle(fontSize: 12))
                          ])
                        ],
                        const SizedBox(height: 18),
                        Row(children: [
                          Text(formatNpr(product.price),
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w800)),
                          if (product.discountPercent > 0) ...[
                            const SizedBox(width: 12),
                            Text(formatNpr(product.originalPrice!),
                                style: const TextStyle(
                                    color: AppColors.muted,
                                    decoration: TextDecoration.lineThrough)),
                            const SizedBox(width: 8),
                            Text('${product.discountPercent}% OFF',
                                style: const TextStyle(
                                    color: AppColors.brand,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800))
                          ]
                        ]),
                        const SizedBox(height: 12),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                                color: product.canOrder
                                    ? AppColors.lime
                                    : AppColors.warm,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                                product.isAvailable
                                    ? 'Available'
                                    : product.canOrder
                                        ? 'Availability confirmed at checkout'
                                        : 'Currently unavailable',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.brand))),
                        const SizedBox(height: 22),
                        const Divider(),
                        const SizedBox(height: 18),
                        const Text('Product details',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        Text(
                            product.description.isEmpty
                                ? 'Product details have not been provided yet.'
                                : product.description,
                            style: const TextStyle(
                                color: AppColors.muted, height: 1.6)),
                        if (product.unit != null) ...[
                          const SizedBox(height: 12),
                          Text('Pack size: ${product.unit}',
                              style: const TextStyle(fontSize: 12))
                        ],
                        const SizedBox(height: 24),
                        const Row(children: [
                          Icon(Icons.payments_outlined, color: AppColors.brand),
                          SizedBox(width: 10),
                          Expanded(
                              child: Text(
                                  'Cash on delivery · Pay when it arrives',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)))
                        ]),
                        if (related.isNotEmpty) ...[
                          const SizedBox(height: 30),
                          const SectionHeading(title: 'You might also need'),
                          const SizedBox(height: 14),
                          SizedBox(
                              height: 258,
                              child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: related.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) => SizedBox(
                                      width: 166,
                                      child: ProductCard(
                                          product: related[index]))))
                        ]
                      ]))
            ])),
        bottomNavigationBar: SafeArea(
            top: false,
            child: ScreenFrame(
                maxWidth: 760,
                child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: AppColors.line))),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            Text(formatNpr(product.price),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800)),
                            Text(product.unit ?? 'Standard pack',
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.muted))
                          ])),
                      if (quantity > 0) ...[
                        QuantityControl(product: product, quantity: quantity),
                        const SizedBox(width: 12),
                        TextButton(
                            onPressed: () => _basket(context),
                            child: const Text('View basket',
                                style: TextStyle(fontSize: 12)))
                      ] else
                        ElevatedButton.icon(
                            onPressed: product.canOrder
                                ? () => state.addToCart(product)
                                : null,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(product.canOrder
                                ? 'Add to cart'
                                : 'Unavailable'))
                    ])))));
  }
}
