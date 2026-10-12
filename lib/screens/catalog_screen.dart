import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/common.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => CatalogScreenState();
}

class CatalogScreenState extends State<CatalogScreen> {
  final _search = TextEditingController();
  String? _category;
  var _sort = 'featured';
  var _inStockOnly = false;
  var _dealsOnly = false;

  void selectCategory(String? categoryId) =>
      setState(() => _category = categoryId);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    var items = state.search(_search.text, categoryId: _category);
    if (_inStockOnly) {
      items = items.where((product) => product.isAvailable).toList(growable: false);
    }
    if (_dealsOnly) {
      items = items
          .where((product) => product.discountPercent > 0)
          .toList(growable: false);
    }

    final sorted = [...items];
    if (_sort == 'low') sorted.sort((a, b) => a.price.compareTo(b.price));
    if (_sort == 'high') sorted.sort((a, b) => b.price.compareTo(a.price));
    if (_sort == 'new') {
      sorted.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
    }
    if (_sort == 'featured') {
      sorted.sort((a, b) =>
          (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0));
    }

    return CustomScrollView(
      key: const PageStorageKey('catalog-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search name, SKU, brand or category',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => setState(_search.clear),
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 47,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChoiceChip(
                  selected: _category == null,
                  label: const Text('All'),
                  onSelected: (_) => setState(() => _category = null),
                ),
                const SizedBox(width: 8),
                ...state.categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: _category == category.id,
                      label: Text(category.name),
                      onSelected: (_) =>
                          setState(() => _category = category.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 49,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  selected: _inStockOnly,
                  label: const Text('In stock'),
                  avatar: const Icon(Icons.inventory_2_outlined, size: 17),
                  onSelected: (value) => setState(() => _inStockOnly = value),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _dealsOnly,
                  label: const Text('Deals'),
                  avatar: const Icon(Icons.local_offer_outlined, size: 17),
                  onSelected: (value) => setState(() => _dealsOnly = value),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${sorted.length} products',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                DropdownButton<String>(
                  value: _sort,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(12),
                  items: const [
                    DropdownMenuItem(
                        value: 'featured', child: Text('Best match')),
                    DropdownMenuItem(
                        value: 'new', child: Text('New arrivals')),
                    DropdownMenuItem(value: 'low', child: Text('Price: low')),
                    DropdownMenuItem(value: 'high', child: Text('Price: high')),
                  ],
                  onChanged: (value) => setState(() => _sort = value!),
                ),
              ],
            ),
          ),
        ),
        if (sorted.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.search_off,
              title: 'No matching products',
              message: 'Try another search or clear one of the filters.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.crossAxisExtent >= 760 ? 4 : 2;
                return SliverGrid.builder(
                  itemCount: sorted.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: columns == 2 ? .55 : .59,
                  ),
                  itemBuilder: (context, index) =>
                      ProductCard(product: sorted[index]),
                );
              },
            ),
          ),
      ],
    );
  }
}
