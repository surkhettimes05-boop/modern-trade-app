import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../demo/demo_product_assets.dart';
import '../main.dart';
import '../models/models.dart';
import '../screens/product_screen.dart';

class PasalhoLogo extends StatelessWidget {
  const PasalhoLogo({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 34 : 40,
            height: compact ? 34 : 40,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              'P',
              style: TextStyle(
                color: AppColors.lime,
                fontSize: compact ? 18 : 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'pasalho.',
            style: TextStyle(
              color: AppColors.brand,
              fontSize: 22,
              letterSpacing: -.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.eyebrow,
    this.action,
  });
  final String title;
  final String? eyebrow;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.6,
                      ),
                ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      );
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final quantity = state.cartController.quantities[product.id] ?? 0;
    void detail() => Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => ProductScreen(product: product)));
    return Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: InkWell(
                  onTap: detail,
                  child: Stack(fit: StackFit.expand, children: [
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: ProductImage(
                            url: DemoProductAssets.imageFor(product))),
                    if (product.discountPercent > 0)
                      Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                  color: AppColors.lime,
                                  borderRadius: BorderRadius.circular(5)),
                              child: Text('${product.discountPercent}% OFF',
                                  style: const TextStyle(
                                      color: AppColors.brand,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800))))
                  ]))),
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        product.brand.isEmpty
                            ? 'EVERYDAY ESSENTIAL'
                            : product.brand.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 8,
                            color: AppColors.muted,
                            letterSpacing: .5)),
                    const SizedBox(height: 5),
                    SizedBox(
                        height: 36,
                        child: InkWell(
                            onTap: detail,
                            child: Text(product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    fontWeight: FontWeight.w700)))),
                    const SizedBox(height: 5),
                    Text(product.unit ?? 'Standard pack',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.muted)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(formatNpr(product.price),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w800)),
                            if (product.discountPercent > 0)
                              Text(formatNpr(product.originalPrice!),
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.muted,
                                      decoration: TextDecoration.lineThrough))
                          ])),
                      if (quantity > 0)
                        QuantityControl(
                            product: product, quantity: quantity, compact: true)
                      else
                        SizedBox(
                            height: 34,
                            child: ElevatedButton(
                                onPressed: product.canOrder
                                    ? () => state.addToCart(product)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(58, 34),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    backgroundColor: AppColors.lime,
                                    foregroundColor: AppColors.brand,
                                    side: const BorderSide(
                                        color: AppColors.brand),
                                    textStyle: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800)),
                                child: Text(
                                    product.canOrder ? 'ADD' : 'Unavailable')))
                    ])
                  ]))
        ]));
  }
}

class QuantityControl extends StatelessWidget {
  const QuantityControl(
      {super.key,
      required this.product,
      required this.quantity,
      this.compact = false});
  final Product product;
  final int quantity;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
      height: compact ? 34 : 40,
      decoration: BoxDecoration(
          color: AppColors.brand, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
            width: compact ? 26 : 38,
            child: IconButton(
                tooltip: 'Decrease quantity',
                padding: EdgeInsets.zero,
                onPressed: () =>
                    AppScope.of(context).setCartQuantity(product, quantity - 1),
                icon: Icon(Icons.remove,
                    size: compact ? 14 : 18, color: Colors.white))),
        Text('$quantity',
            style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w700)),
        SizedBox(
            width: compact ? 26 : 38,
            child: IconButton(
                tooltip: 'Increase quantity',
                padding: EdgeInsets.zero,
                onPressed: () =>
                    AppScope.of(context).setCartQuantity(product, quantity + 1),
                icon: Icon(Icons.add,
                    size: compact ? 14 : 18, color: Colors.white)))
      ]));
}

class ScreenFrame extends StatelessWidget {
  const ScreenFrame({super.key, required this.child, this.maxWidth = 1200});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
      heightFactor: 1,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth), child: child));
}

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, this.fit = BoxFit.contain});
  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty || url.startsWith('/')) {
      return const ColoredBox(
        color: AppColors.cream,
        child: Center(
          child: Icon(Icons.inventory_2_outlined,
              color: AppColors.muted, size: 42),
        ),
      );
    }
    final cacheWidth = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .clamp(240, 1200)
        .round();
    Widget error(BuildContext _, Object __, StackTrace? ___) =>
        const ColoredBox(
          color: AppColors.cream,
          child: Center(
            child: Icon(Icons.inventory_2_outlined,
                color: AppColors.muted, size: 42),
          ),
        );
    if (url.startsWith('assets/')) {
      return ColoredBox(
        color: AppColors.cream,
        child: Image.asset(
          url,
          fit: fit,
          cacheWidth: cacheWidth,
          filterQuality: FilterQuality.high,
          errorBuilder: error,
        ),
      );
    }
    return Image.network(
      url,
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: error,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ColoredBox(
              color: AppColors.cream,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 58, color: AppColors.brand),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.5),
              ),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      );
}
