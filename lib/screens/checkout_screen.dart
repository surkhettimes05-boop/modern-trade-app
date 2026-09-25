import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/api_client.dart';
import '../main.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postalCode = TextEditingController();
  final _notes = TextEditingController();
  String _deliveryType = 'DELIVERY';
  bool _busy = false;
  String? _error;
  Future<List<Map<String, dynamic>>>? _savedAddresses;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = AppScope.of(context);
    _name.text = state.customer?.preferredName ?? '';
    _savedAddresses = _loadAddresses(state);
  }

  Future<List<Map<String, dynamic>>> _loadAddresses(AppState state) async {
    final response =
        await state.customerRepository.loadAddresses(state.customer!.id);
    final rows = response is List
        ? response
        : response is Map && response['data'] is List
            ? response['data'] as List
            : const [];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  void _useAddress(Map<String, dynamic> address) {
    String value(String key) => address[key]?.toString().trim() ?? '';
    final streetAddress = [
      value('house_number'),
      value('street'),
      value('tole_locality'),
      value('landmark'),
    ].where((part) => part.isNotEmpty).join(', ');
    setState(() {
      final savedName = value('recipient_name');
      final savedPhone = value('phone');
      if (savedName.isNotEmpty) _name.text = savedName;
      if (savedPhone.isNotEmpty) _phone.text = savedPhone;
      _address.text = streetAddress;
      _city.text =
          value('city').isNotEmpty ? value('city') : value('municipality');
      _state.text =
          value('state').isNotEmpty ? value('state') : value('province');
      _postalCode.text = value('postal_code');
      final instructions = value('delivery_instructions');
      if (instructions.isNotEmpty) _notes.text = instructions;
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _address,
      _city,
      _state,
      _postalCode,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value?.trim().isEmpty == true ? 'Required' : null;

  Future<void> _placeOrder() async {
    if (_busy) return;
    if (!_form.currentState!.validate()) return;
    final state = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await state.checkout(
        deliveryType: _deliveryType,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        postalCode: _postalCode.text.trim(),
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon:
              const Icon(Icons.check_circle, color: AppColors.brand, size: 52),
          title: const Text('Order confirmed'),
          content: Text(
            'Your COD order ${order.orderNumber ?? order.id} has been received.\n\n'
            'Server total: ${formatNpr(order.total)}\n'
            'Payment: Cash on delivery\n'
            'Fulfilment: ${order.deliveryType ?? _deliveryType}\n'
            'Status: ${order.status.replaceAll('_', ' ')}',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (exception) {
      setState(() => _error = userMessage(exception));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Text('Fulfilment',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'DELIVERY',
                  icon: Icon(Icons.local_shipping_outlined),
                  label: Text('Delivery'),
                ),
                ButtonSegment(
                  value: 'PICKUP',
                  icon: Icon(Icons.store_outlined),
                  label: Text('Pickup'),
                ),
              ],
              selected: {_deliveryType},
              onSelectionChanged: (value) {
                setState(() => _deliveryType = value.first);
                _form.currentState?.validate();
              },
            ),
            if (_deliveryType == 'PICKUP') ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.store, color: AppColors.brand),
                  title: Text(state.selectedStore?.name ?? 'No store selected'),
                  subtitle:
                      Text(state.selectedStore?.address ?? 'Pickup store'),
                ),
              ),
            ],
            if (_deliveryType == 'DELIVERY' && _savedAddresses != null) ...[
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _savedAddresses,
                builder: (context, snapshot) {
                  final addresses = snapshot.data ?? const [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  if (addresses.isEmpty) return const SizedBox.shrink();
                  return Card(
                    child: Column(
                      children: [
                        const ListTile(
                          leading: Icon(Icons.location_on_outlined,
                              color: AppColors.brand),
                          title: Text('Use a saved address',
                              style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                        ...addresses.map((address) => ListTile(
                              title: Text(address['address_type']?.toString() ??
                                  'Saved address'),
                              subtitle: Text([
                                address['street'],
                                address['tole_locality'],
                                address['city'] ?? address['municipality'],
                              ]
                                  .where((part) =>
                                      part?.toString().trim().isNotEmpty ==
                                      true)
                                  .join(', ')),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _useAddress(address),
                            )),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            Text('Contact and address',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              validator: _required,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              validator: (value) =>
                  RegExp(r'^(\+977)?9[6-9]\d{8}$').hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Enter a valid Nepal mobile number',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Mobile number'),
            ),
            const SizedBox(height: 12),
            if (_deliveryType == 'DELIVERY') ...[
              TextFormField(
                controller: _address,
                validator: _required,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Street, ward and locality'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _city,
                      validator: _required,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          labelText: 'City / municipality'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _state,
                      validator: _required,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Province'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _postalCode,
                validator: _required,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Postal code'),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText:
                      '${_deliveryType == 'PICKUP' ? 'Pickup' : 'Delivery'} notes (optional)'),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.payments_outlined, color: AppColors.brand),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Cash on delivery',
                              style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                        Icon(Icons.check_circle, color: AppColors.brand),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        const Expanded(child: Text('Estimated subtotal')),
                        Text(formatNpr(state.cartSubtotal),
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: ElevatedButton(
            onPressed: _busy ? null : _placeOrder,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('Place COD order · ${formatNpr(state.cartSubtotal)}'),
          ),
        ),
      ),
    );
  }
}
