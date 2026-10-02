import 'package:flutter/material.dart';

import '../main.dart';
import '../core/app_theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'catalog_screen.dart';
import 'home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 0;
  final _catalogKey = GlobalKey<CatalogScreenState>();
  void _openShop([String? categoryId]) {
    setState(() => _index = 1);
    _catalogKey.currentState?.selectCategory(categoryId);
  }

  late final _pages = <Widget>[
    HomeScreen(onShop: _openShop),
    CatalogScreen(key: _catalogKey),
    CartScreen(onShop: _openShop),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PasalhoLogo(),
              SizedBox(height: 28),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }
    if (state.catalogLoading && state.products.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PasalhoLogo(),
              SizedBox(height: 28),
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('Loading the PASALHO central catalog…'),
            ],
          ),
        ),
      );
    }
    if (state.error != null && state.products.isEmpty) {
      final isConfigurationError = const {
        'APP_ENV must be development or production.',
        'This release build is missing APP_ENV=production.',
        'APP_ENV must be development, demo or production.',
        'This release build requires APP_ENV=production or APP_ENV=demo.',
        'Production API configuration is missing.',
        'The API base URL is invalid.',
        'Production API traffic must use HTTPS.',
      }.contains(state.error);
      return Scaffold(
        appBar: AppBar(title: const PasalhoLogo(compact: true)),
        body: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: isConfigurationError
              ? 'PASALHO configuration error'
              : 'Unable to connect to PASALHO',
          message: state.error!,
          action: ElevatedButton.icon(
            onPressed: state.catalogLoading ? null : state.loadCatalog,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      );
    }
    return Scaffold(
        appBar: AppBar(
            toolbarHeight: 76,
            titleSpacing: 16,
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('pasalho.',
                  style: TextStyle(
                      color: AppColors.brand,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.7)),
              const SizedBox(height: 5),
              Text(
                  [
                    'Deliver to your doorstep',
                    'Find your daily essentials',
                    'Your basket',
                    'Your account'
                  ][_index],
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4)),
              if (_index == 0)
                const Text('Choose your address at checkout',
                    style: TextStyle(fontSize: 10, color: AppColors.muted))
            ]),
            actions: [
              IconButton(
                  tooltip: 'Account',
                  onPressed: () => setState(() => _index = 3),
                  icon: const Icon(Icons.account_circle_outlined,
                      color: AppColors.brand, size: 28)),
              const SizedBox(width: 8)
            ]),
        body: ScreenFrame(child: IndexedStack(index: _index, children: _pages)),
        bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
          if (state.cartCount > 0 && _index < 2)
            ScreenFrame(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: ElevatedButton(
                        onPressed: () => setState(() => _index = 2),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52)),
                        child: Row(children: [
                          const Icon(Icons.shopping_bag_outlined, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(
                                  '${state.cartCount} ${state.cartCount == 1 ? 'item' : 'items'} · ${formatNpr(state.cartSubtotal)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700))),
                          const Text('View basket',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18)
                        ])))),
          Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.line))),
              child: ScreenFrame(
                  child: NavigationBar(
                      selectedIndex: _index,
                      onDestinationSelected: (value) =>
                          setState(() => _index = value),
                      destinations: [
                    const NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home, color: AppColors.brand),
                        label: 'Home'),
                    const NavigationDestination(
                        icon: Icon(Icons.grid_view_outlined),
                        selectedIcon:
                            Icon(Icons.grid_view, color: AppColors.brand),
                        label: 'Categories'),
                    NavigationDestination(
                        icon: Badge(
                            isLabelVisible: state.cartCount > 0,
                            label: Text('${state.cartCount}'),
                            child: const Icon(Icons.shopping_bag_outlined)),
                        selectedIcon: const Icon(Icons.shopping_bag,
                            color: AppColors.brand),
                        label: 'Cart'),
                    const NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon:
                            Icon(Icons.person, color: AppColors.brand),
                        label: 'Account')
                  ])))
        ]));
  }
}
