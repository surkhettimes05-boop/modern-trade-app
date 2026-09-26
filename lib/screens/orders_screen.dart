import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/api_client.dart';
import '../main.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<CustomerOrder>> _orders;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orders = AppScope.of(context).loadOrders();
  }

  Future<void> _reload() async {
    setState(() => _orders = AppScope.of(context).loadOrders());
    await _orders;
  }

  Future<void> _cancel(CustomerOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'The store will stop fulfilment if the order is still eligible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      if (AppScope.of(context).isDemo) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Demo orders are local presentation records.')));
        return;
      }
      await AppScope.of(context).api.post(
        '/api/customer/orders/${order.id}/cancel',
        body: {'reason': 'Cancelled by customer from Flutter app'},
      );
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled')),
        );
      }
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage(exception))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My orders')),
        body: FutureBuilder<List<CustomerOrder>>(
          future: _orders,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load orders',
                message: userMessage(snapshot.error!),
                action: ElevatedButton(
                    onPressed: _reload, child: const Text('Try again')),
              );
            }
            final orders = snapshot.data ?? const [];
            if (orders.isEmpty) {
              return const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message: 'Your completed checkouts will appear here.',
              );
            }
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _OrderCard(
                  order: orders[index],
                  onCancel: () => _cancel(orders[index]),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            _OrderDetailScreen(order: orders[index])),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onCancel,
    required this.onTap,
  });
  final CustomerOrder order;
  final VoidCallback onCancel;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.orderNumber ??
                            'Order ${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F2ED),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        order.status.replaceAll('_', ' '),
                        style: const TextStyle(
                          color: AppColors.brand,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      order.deliveryType == 'PICKUP'
                          ? Icons.store_outlined
                          : Icons.local_shipping_outlined,
                      size: 19,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Text(order.deliveryType ?? 'DELIVERY'),
                    const Spacer(),
                    Text(formatNpr(order.total),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
                if (order.orderDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    order.orderDate!.toLocal().toString().split('.').first,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
                if (order.status == 'PENDING_PAYMENT' ||
                    order.status == 'CONFIRMED') ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancel order'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class _OrderDetailScreen extends StatelessWidget {
  const _OrderDetailScreen({required this.order});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Order details')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.check_circle, color: AppColors.brand, size: 58),
            const SizedBox(height: 16),
            Text(order.orderNumber ?? order.id,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(order.status.replaceAll('_', ' '),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.brand, fontWeight: FontWeight.w800)),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailRow('Payment', 'Cash on delivery'),
                    const Divider(height: 24),
                    _detailRow('Fulfilment', order.deliveryType ?? 'DELIVERY'),
                    const Divider(height: 24),
                    _detailRow('Total', formatNpr(order.total)),
                    if (order.orderDate != null) ...[
                      const Divider(height: 24),
                      _detailRow(
                          'Placed',
                          order.orderDate!
                              .toLocal()
                              .toString()
                              .split('.')
                              .first),
                    ],
                  ],
                ),
              ),
            ),
            if (order.id.startsWith('DEMO-')) ...[
              const SizedBox(height: 16),
              const Text(
                'Demo orders are stored locally and are not sent to the PASALHO backend.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
            ],
          ],
        ),
      );

  Widget _detailRow(String label, String value) => Row(
        children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: AppColors.muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      );
}
