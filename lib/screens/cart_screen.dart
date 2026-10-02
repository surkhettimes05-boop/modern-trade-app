import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../demo/demo_product_assets.dart';
import '../main.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.onShop});
  final VoidCallback onShop;
  Future<void> _checkout(BuildContext context) async {
    final state = AppScope.of(context);
    if (!state.isSignedIn) {
      final signedIn = await Navigator.push<bool>(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (signedIn != true || !context.mounted) return;
    }
    if (context.mounted) {
      await Navigator.push<void>(
          context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.cart.isEmpty) {
      return EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Your basket is waiting',
          message: 'Add your daily essentials. We’ll keep them here for you.',
          action: ElevatedButton(
              onPressed: onShop, child: const Text('Start shopping')));
    }
    return ScreenFrame(
        maxWidth: 760,
        child: Column(children: [
          Expanded(
              child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.shopping_bag_outlined,
                      color: AppColors.brand),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('${state.cartCount} items in your basket',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        const Text('Your everyday essentials, together.',
                            style:
                                TextStyle(fontSize: 11, color: AppColors.muted))
                      ])),
                  TextButton(
                      onPressed: onShop,
                      child: const Text('Add more',
                          style: TextStyle(fontSize: 11)))
                ])),
            const SizedBox(height: 16),
            Card(
                margin: EdgeInsets.zero,
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      for (final (index, line) in state.cart.indexed) ...[
                        _CartLineItem(line: line),
                        if (index < state.cart.length - 1)
                          const Divider(height: 28)
                      ]
                    ]))),
            const SizedBox(height: 16),
            Card(
                margin: EdgeInsets.zero,
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bill details',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 18),
                          Row(children: [
                            const Expanded(child: Text('Items subtotal')),
                            Text(formatNpr(state.cartSubtotal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800))
                          ]),
                          const Divider(height: 28),
                          const Row(children: [
                            Icon(Icons.payments_outlined,
                                color: AppColors.brand, size: 20),
                            SizedBox(width: 8),
                            Text('Pay in cash when your order arrives',
                                style: TextStyle(fontSize: 12))
                          ]),
                          const SizedBox(height: 12),
                          const Text(
                              'Delivery charges, taxes and availability are confirmed when your order is placed.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                  height: 1.5))
                        ]))),
          ])),
          SafeArea(
              top: false,
              child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.line))),
                  child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: () => _checkout(context),
                          child: Row(children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(formatNpr(state.cartSubtotal),
                                      style: const TextStyle(fontSize: 16)),
                                  const Text('ITEMS SUBTOTAL',
                                      style: TextStyle(
                                          fontSize: 8, letterSpacing: .5))
                                ]),
                            const Spacer(),
                            const Text('Continue to checkout',
                                style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward, size: 18)
                          ])))))
        ]));
  }
}

class _CartLineItem extends StatelessWidget {
  const _CartLineItem({required this.line});
  final CartLine line;
  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
            width: 64,
            height: 72,
            child: ProductImage(url: DemoProductAssets.imageFor(line.product))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(line.product.name,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 5),
          Text(line.product.unit ?? 'Standard pack',
              style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          const SizedBox(height: 7),
          Text(formatNpr(line.totalMinor / 100),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))
        ])),
        const SizedBox(width: 8),
        QuantityControl(
            product: line.product, quantity: line.quantity, compact: true)
      ]);
}
