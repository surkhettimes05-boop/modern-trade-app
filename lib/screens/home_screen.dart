import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../main.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/storefront.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onShop});
  final ValueChanged<String?> onShop;
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final departments = shopDepartments(state.categories, state.products);
    final care = state.products
        .where((p) => RegExp('care|clean|laundry')
            .hasMatch(inferredDepartment(p).toLowerCase()))
        .toList();
    return RefreshIndicator(
        onRefresh: state.loadCatalog,
        child: ListView(
            key: const PageStorageKey('home-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              InkWell(
                  onTap: () => onShop(null),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.line)),
                      child: const Row(children: [
                        Icon(Icons.search, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                            child: Text('Search groceries, snacks & more',
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 13)))
                      ]))),
              const SizedBox(height: 18),
              LayoutBuilder(
                  builder: (context, constraints) => Container(
                      height: constraints.maxWidth > 700 ? 260 : 215,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                              colors: [Color(0xFFEAF7E3), Color(0xFFD3ECC0)])),
                      child: Stack(children: [
                        Positioned(
                            right: -30,
                            bottom: -20,
                            width: constraints.maxWidth > 700 ? 400 : 160,
                            height: constraints.maxWidth > 700 ? 290 : 170,
                            child: Transform.rotate(
                                angle: -.07,
                                child: Image.asset(
                                    'assets/images/storefront/snacks.png',
                                    fit: BoxFit.cover))),
                        Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.eco_outlined,
                                            size: 14, color: AppColors.brand),
                                        SizedBox(width: 5),
                                        Text('EVERYDAY ESSENTIALS',
                                            style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.brand,
                                                letterSpacing: .8))
                                      ]),
                                  const SizedBox(height: 12),
                                  Text(
                                      'Your everyday basket.\nA little greener.',
                                      style: TextStyle(
                                          fontSize: constraints.maxWidth > 700
                                              ? 38
                                              : 25,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -.8,
                                          height: 1.12,
                                          color: AppColors.brand)),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Good things for your daily routine.',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.muted)),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                      height: 36,
                                      child: ElevatedButton(
                                          onPressed: () => onShop(null),
                                          style: ElevatedButton.styleFrom(
                                              minimumSize: const Size(0, 36),
                                              textStyle: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800)),
                                          child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Start shopping'),
                                                SizedBox(width: 8),
                                                Icon(Icons.arrow_forward,
                                                    size: 14)
                                              ])))
                                ]))
                      ]))),
              const SizedBox(height: 26),
              SectionHeading(
                  title: 'Shop by category',
                  action: TextButton(
                      onPressed: () => onShop(null),
                      child: const Text('See all',
                          style: TextStyle(fontSize: 12)))),
              const SizedBox(height: 12),
              LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: departments.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: constraints.maxWidth > 700 ? 8 : 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 110),
                      itemBuilder: (context, index) {
                        final d = departments[index];
                        return InkWell(
                            onTap: () => onShop(d.id),
                            borderRadius: BorderRadius.circular(12),
                            child: Column(children: [
                              Expanded(
                                  child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                          color: const [
                                            Color(0xFFEAF4E3),
                                            Color(0xFFFFF1D8),
                                            Color(0xFFE8F2F8),
                                            Color(0xFFF8EAF0)
                                          ][index % 4],
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      child: Icon(d.icon,
                                          size: 34, color: AppColors.brand))),
                              const SizedBox(height: 8),
                              SizedBox(
                                  height: 30,
                                  child: Text(d.name,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3)))
                            ]));
                      })),
              const SizedBox(height: 24),
              SectionHeading(
                  title: 'Everyday essentials',
                  action: TextButton(
                      onPressed: () => onShop(null),
                      child: const Text('See all',
                          style: TextStyle(fontSize: 12)))),
              const SizedBox(height: 12),
              _ProductRail(products: state.products),
              const SizedBox(height: 24),
              InkWell(
                  onTap: () => onShop(departments
                      .where((d) => d.name.contains('Snacks'))
                      .firstOrNull
                      ?.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFF1D8),
                          borderRadius: BorderRadius.circular(16)),
                      child: const Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('THE SNACK BREAK',
                                  style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w800)),
                              SizedBox(height: 9),
                              Text('Make room for\nyour favourites.',
                                  style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1)),
                              SizedBox(height: 12),
                              Text('Explore snacks',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700))
                            ])),
                        Icon(Icons.ramen_dining,
                            size: 65, color: Color(0xFFAA7838))
                      ]))),
              if (care.isNotEmpty) ...[
                const SizedBox(height: 26),
                const SectionHeading(title: 'Home & personal care'),
                const SizedBox(height: 12),
                _ProductRail(products: care)
              ],
              const SizedBox(height: 30),
              const Row(children: [
                Icon(Icons.payments_outlined, color: AppColors.brand, size: 26),
                SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Pay when it arrives',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Cash on delivery. Your daily needs, together.',
                          style:
                              TextStyle(fontSize: 11, color: AppColors.muted))
                    ]))
              ])
            ]));
  }
}

class _ProductRail extends StatelessWidget {
  const _ProductRail({required this.products});
  final List<Product> products;
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 258,
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) => SizedBox(
              width: 166, child: ProductCard(product: products[index]))));
}
