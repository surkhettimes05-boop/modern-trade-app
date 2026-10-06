import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/api_client.dart';
import '../main.dart';
import '../models/models.dart';

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
  List<Map<String, dynamic>> _areas = [];
  int? _municipalityId;
  int? _wardId;
  Map<String, dynamic>? _quote;
  bool _loadingAreas = false;
  bool _initialized = false;
  int _quoteRequest = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadAreas();
    }
  }

  Future<void> _loadAreas() async {
    final state = AppScope.of(context);
    final store = state.selectedStore;
    if (store == null) return;
    setState(() {
      _loadingAreas = true;
      _error = null;
    });
    try {
      final areas = await state.checkoutRepository.deliveryAreas(store.id);
      if (mounted) setState(() => _areas = areas);
    } catch (e) {
      if (mounted) setState(() => _error = userMessage(e));
    } finally {
      if (mounted) setState(() => _loadingAreas = false);
    }
  }

  Future<void> _loadQuote() async {
    final state = AppScope.of(context);
    final request = ++_quoteRequest;
    setState(() {
      _quote = null;
      _error = null;
    });
    if (_municipalityId == null ||
        _wardId == null ||
        state.selectedStore == null)
      return;
    try {
      final quote = await state.checkoutRepository.deliveryQuote(
        state.selectedStore!.id,
        _municipalityId!,
        _wardId!,
        state.cartSubtotal,
      );
      if (mounted && request == _quoteRequest) setState(() => _quote = quote);
    } catch (e) {
      if (mounted && request == _quoteRequest)
        setState(() => _error = userMessage(e));
    }
  }

  final _postalCode = TextEditingController();
  final _notes = TextEditingController();
  String _deliveryType = 'DELIVERY';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _phone, _address, _postalCode, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value?.trim().isEmpty == true ? 'Required' : null;

  Future<void> _placeOrder() async {
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
        municipalityId: _municipalityId,
        wardId: _wardId,
        postalCode: _postalCode.text.trim(),
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: AppColors.brand,
            size: 52,
          ),
          title: const Text('Order confirmed'),
          content: Text(
            'Your COD order ${order.orderNumber ?? order.id} has been received.',
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
      if (mounted) setState(() => _error = userMessage(exception));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final municipality = _areas
        .where((area) => area['id'] == _municipalityId)
        .firstOrNull;
    final wards = (municipality?['wards'] as List?) ?? [];
    final fee = num.tryParse('${_quote?['delivery_fee']}')?.toDouble() ?? 0;
    final total = state.cartSubtotal + (_deliveryType == 'DELIVERY' ? fee : 0);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Text(
              'Fulfilment',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
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
                  subtitle: Text(
                    state.selectedStore?.address ?? 'Pickup store',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Contact and address',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
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
                  labelText: 'Street, ward and locality',
                ),
              ),
              const SizedBox(height: 12),
              if (_loadingAreas) const LinearProgressIndicator(),
              DropdownButtonFormField<int>(
                initialValue: _municipalityId,
                decoration: const InputDecoration(labelText: 'Municipality'),
                items: _areas
                    .map(
                      (area) => DropdownMenuItem<int>(
                        value: area['id'] as int,
                        child: Text('${area['name_en']}'),
                      ),
                    )
                    .toList(),
                validator: (value) =>
                    value == null ? 'Choose municipality' : null,
                onChanged: _busy
                    ? null
                    : (value) {
                        setState(() {
                          _municipalityId = value;
                          _wardId = null;
                          _quote = null;
                        });
                        _quoteRequest++;
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey(_municipalityId),
                initialValue: _wardId,
                decoration: const InputDecoration(labelText: 'Ward'),
                items: wards
                    .map(
                      (ward) => DropdownMenuItem<int>(
                        value: ward['id'] as int,
                        child: Text('Ward ${ward['ward_number']}'),
                      ),
                    )
                    .toList(),
                validator: (value) => value == null ? 'Choose ward' : null,
                onChanged: _busy
                    ? null
                    : (value) {
                        setState(() => _wardId = value);
                        _loadQuote();
                      },
              ),
              if (_areas.isEmpty && !_loadingAreas)
                TextButton(
                  onPressed: _loadAreas,
                  child: const Text('Retry loading delivery areas'),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _postalCode,
                validator: (value) => RegExp(r'^\d{5}$').hasMatch(value ?? '')
                    ? null
                    : 'Enter 5-digit postal code',
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
                    '${_deliveryType == 'PICKUP' ? 'Pickup' : 'Delivery'} notes (optional)',
              ),
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
                          child: Text(
                            'Cash on delivery',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Icon(Icons.check_circle, color: AppColors.brand),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        const Expanded(child: Text('Order subtotal')),
                        Text(
                          formatNpr(state.cartSubtotal),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_deliveryType == 'DELIVERY')
              Text(
                _quote?['serviceable'] == true
                    ? 'Delivery fee: ${formatNpr(fee)}. Final prices are checked at checkout.'
                    : 'Select an available delivery area to confirm the delivery fee.',
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
            onPressed:
                _busy ||
                    (_deliveryType == 'DELIVERY' &&
                        _quote?['serviceable'] != true)
                ? null
                : _placeOrder,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Place COD order · ${formatNpr(total)}'),
          ),
        ),
      ),
    );
  }
}
