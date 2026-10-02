import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../main.dart';
import '../widgets/common.dart';
import '../widgets/storefront.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => CatalogScreenState();
}

class CatalogScreenState extends State<CatalogScreen> {
  final _search = TextEditingController();
  String? _category;
  var _sort = 'featured';
  void selectCategory(String? categoryId) => setState(() {
        _category = categoryId;
        _search.clear();
      });
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final departments = shopDepartments(state.categories, state.products);
    final sorted = state
        .search(_search.text)
        .where((p) => matchesDepartment(p, _category))
        .toList();
    if (_sort == 'low') sorted.sort((a, b) => a.price.compareTo(b.price));
    if (_sort == 'high') sorted.sort((a, b) => b.price.compareTo(a.price));
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  hintText: 'Search groceries, snacks & more',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => setState(_search.clear),
                          icon: const Icon(Icons.close))))),
      Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: MediaQuery.sizeOf(context).width > 700 ? 125 : 82,
            child: ListView(padding: const EdgeInsets.only(top: 8), children: [
              _department(null, 'All', Icons.shopping_basket_outlined),
              ...departments.map((d) => _department(d.id, d.name, d.icon))
            ])),
        Expanded(
            child: Container(
                color: Colors.white,
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(children: [
                        Expanded(
                            child: Text('${sorted.length} products',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700))),
                        DropdownButton<String>(
                            value: _sort,
                            underline: const SizedBox.shrink(),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.ink),
                            items: const [
                              DropdownMenuItem(
                                  value: 'featured', child: Text('Featured')),
                              DropdownMenuItem(
                                  value: 'low', child: Text('Price: low')),
                              DropdownMenuItem(
                                  value: 'high', child: Text('Price: high'))
                            ],
                            onChanged: (v) => setState(() => _sort = v!))
                      ])),
                  Expanded(
                      child: sorted.isEmpty
                          ? EmptyState(
                              icon: Icons.search_off,
                              title: 'No matching products',
                              message:
                                  'Try another search or choose a different category.',
                              action: TextButton(
                                  onPressed: () => setState(() {
                                        _category = null;
                                        _search.clear();
                                      }),
                                  child: const Text('Clear filters')))
                          : LayoutBuilder(builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 900
                                  ? 5
                                  : constraints.maxWidth >= 650
                                      ? 4
                                      : constraints.maxWidth >= 450
                                          ? 3
                                          : 2;
                              return GridView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 20),
                                  itemCount: sorted.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          mainAxisExtent: 250,
                                          mainAxisSpacing: 10,
                                          crossAxisSpacing: 10),
                                  itemBuilder: (context, index) =>
                                      ProductCard(product: sorted[index]));
                            }))
                ])))
      ]))
    ]);
  }

  Widget _department(String? id, String label, IconData icon) {
    final selected = _category == id;
    return Semantics(
        selected: selected,
        child: InkWell(
            onTap: () => setState(() => _category = id),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 14),
                decoration: BoxDecoration(
                    color: selected ? AppColors.lime : Colors.transparent,
                    border: Border(
                        left: BorderSide(
                            color:
                                selected ? AppColors.brand : Colors.transparent,
                            width: 3))),
                child: Column(children: [
                  Icon(icon,
                      size: 26,
                      color: selected ? AppColors.brand : AppColors.muted),
                  const SizedBox(height: 8),
                  Text(label,
                      maxLines: 3,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          height: 1.3,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w500,
                          color: selected ? AppColors.brand : AppColors.muted))
                ]))));
  }
}
