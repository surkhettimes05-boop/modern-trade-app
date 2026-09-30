import 'package:flutter/material.dart';

import '../main.dart';
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
        title: const PasalhoLogo(compact: true),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_shipping_outlined, size: 18),
                SizedBox(width: 4),
                Text('Central delivery', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: state.cartCount > 0,
              label: Text('${state.cartCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: state.cartCount > 0,
              label: Text('${state.cartCount}'),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(state.isSignedIn ? Icons.person : Icons.person_outline),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
