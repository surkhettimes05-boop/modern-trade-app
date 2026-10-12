import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../main.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onShop});
  final ValueChanged<String?> onShop;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final deals = state.products
        .where((product) => product.discountPercent > 0)
        .take(10)
        .toList(growable: false);
    final newArrivals = [...state.products]
      ..sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
    final featured = state.products
        .where((product) => product.featured && product.isAvailable)
        .toList(growable: false);
    final popular = (featured.isNotEmpty
            ? featured
            : state.products.where((product) => product.isAvailable).toList())
        .take(10)
        .toList(growable: false);
    final promotion = state.offers.where((offer) => offer.featured).firstOrNull ??
        state.offers.firstOrNull;

    return RefreshIndicator(
      onRefresh: state.loadCatalog,
      child: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _SearchPrompt(onTap: () => onShop(null)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _Hero(
                promotion: promotion,
                onShop: () => onShop(null),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: SectionHeading(
                eyebrow: 'Shop faster',
                title: 'Shop by category',
                action: TextButton(
                  onPressed: () => onShop(null),
                  child: const Text('View all'),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 124,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: state.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = state.categories[index];
                  return InkWell(
                    onTap: () => onShop(category.id),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 126,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? AppColors.cream
                            : const Color(0xFFE7F2ED),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (category.imageUrl != null &&
                              category.imageUrl!.isNotEmpty)
                            Opacity(
                              opacity: .28,
                              child: Image.network(
                                category.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(_categoryIcon(category.name),
                                    color: AppColors.brand, size: 28),
                                Text(
                                  category.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    height: 1.1,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (deals.isNotEmpty)
            _ProductSection(
              eyebrow: 'Save on your regulars',
              title: 'Deals',
              products: deals,
              onShop: onShop,
            ),
          if (newArrivals.isNotEmpty)
            _ProductSection(
              eyebrow: 'Freshly added',
              title: 'New arrivals',
              products: newArrivals.take(10).toList(growable: false),
              onShop: onShop,
            ),
          if (popular.isNotEmpty)
            _ProductSection(
              eyebrow: 'Popular picks',
              title: 'Popular right now',
              products: popular,
              onShop: onShop,
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  IconData _categoryIcon(String name) {
    final text = name.toLowerCase();
    if (text.contains('water') || text.contains('drink')) {
      return Icons.local_drink;
    }
    if (text.contains('care') || text.contains('hygiene')) {
      return Icons.spa_outlined;
    }
    if (text.contains('laundry') || text.contains('clean')) {
      return Icons.cleaning_services;
    }
    if (text.contains('rice') || text.contains('flour')) {
      return Icons.grass;
    }
    return Icons.shopping_basket_outlined;
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.eyebrow,
    required this.title,
    required this.products,
    required this.onShop,
  });

  final String eyebrow;
  final String title;
  final List<Product> products;
  final ValueChanged<String?> onShop;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionHeading(
                  eyebrow: eyebrow,
                  title: title,
                  action: TextButton(
                    onPressed: () => onShop(null),
                    child: const Text('Shop all'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 330,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: 176,
                    child: ProductCard(product: products[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.brand, width: 2),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Row(
            children: [
              Icon(Icons.search),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search products, brands and categories',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onShop, this.promotion});
  final VoidCallback onShop;
  final StorefrontOffer? promotion;

  @override
  Widget build(BuildContext context) {
    final image = promotion?.displayImage ??
        'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=85';
    final title = promotion?.title ?? 'Everyday shopping,\ncloser to home.';
    final description = promotion?.description ??
        'Real NPR prices, live store availability, and cash on delivery with Pasalho.';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 350,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: AppColors.brand),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xE5091C13), Color(0x70091C13)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      promotion == null ? 'PASALHO · BIRENDRANAGAR' : 'PASALHO PROMOTION',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      height: 1,
                      letterSpacing: -1.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Color(0xFFEDF5F0), height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton.icon(
                    onPressed: onShop,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Shop now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
