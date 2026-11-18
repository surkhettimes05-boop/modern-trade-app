import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../main.dart';
import '../widgets/common.dart';

class CreatorScreen extends StatefulWidget {
  const CreatorScreen({super.key});

  @override
  State<CreatorScreen> createState() => _CreatorScreenState();
}

class _CreatorScreenState extends State<CreatorScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  ApiClient? _api;
  bool _otpRequested = false;
  bool _loading = false;
  Map<String, dynamic>? _me;
  Map<String, dynamic>? _overview;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api ??= ApiClient(
      baseUrl: AppScope.of(context).api.baseUrl,
      sessionCookieName: 'pasalho_creator_session',
      csrfCookieName: 'pasalho_creator_csrf',
    )..restoreSession().then((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final me = await _api!.get('/api/creator-portal/me');
      final overview =
          await _api!.get('/api/creator-portal/overview');
      if (!mounted) return;
      setState(() {
        _me = Map<String, dynamic>.from(me);
        _overview = Map<String, dynamic>.from(overview);
      });
    } catch (_) {
      // A 401 is handled by the normal signed-out state.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestOtp() async {
    setState(() => _loading = true);
    try {
      await _api!.post('/api/creator-portal/otp/request',
          body: {'phone': _phone.text.trim()});
      if (!mounted) return;
      setState(() => _otpRequested = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('If eligible, a login code was sent.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(userMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _loading = true);
    try {
      await _api!.post('/api/creator-portal/otp/verify',
          body: {'phone': _phone.text.trim(), 'otp_code': _otp.text.trim()});
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(userMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _api!.post('/api/creator-portal/logout');
    await _api!.clearSession();
    if (!mounted) return;
    setState(() {
      _me = null;
      _overview = null;
      _otpRequested = false;
      _otp.clear();
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    _api?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Creator programme')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _me == null
                ? _login(context)
                : _dashboard(context),
      );

  Widget _login(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Creator login',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in with the mobile number registered to your creator account.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile number'),
          ),
          if (_otpRequested) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Login code'),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _otpRequested ? _verifyOtp : _requestOtp,
            child: Text(_otpRequested ? 'Verify code' : 'Request code'),
          ),
        ],
      );

  Widget _dashboard(BuildContext context) {
    final creator = _me!['creator'] is Map
        ? Map<String, dynamic>.from(_me!['creator'] as Map)
        : const <String, dynamic>{};
    final summary = _overview!['summary'] is Map
        ? Map<String, dynamic>.from(_overview!['summary'] as Map)
        : const <String, dynamic>{};
    final ledger = _overview!['ledger'] is Map
        ? Map<String, dynamic>.from(_overview!['ledger'] as Map)
        : const <String, dynamic>{};
    final purchases =
        _overview!['purchases'] is List ? _overview!['purchases'] as List : const [];
    final referralUrl = creator['referral_url']?.toString();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            creator['name']?.toString() ?? 'Creator',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text('Creator code: ${creator['code'] ?? ''}',
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          if (referralUrl != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.link, color: AppColors.brand),
                title: const Text('Referral link'),
                subtitle: Text(referralUrl),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: referralUrl));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Referral link copied')),
                      );
                    }
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric('Clicks', '${summary['clicks'] ?? 0}'),
              _Metric('Registrations', '${summary['registrations'] ?? 0}'),
              _Metric('Attributed sales',
                  'NPR ${summary['attributed_sales_npr'] ?? '0'}'),
              _Metric('Gross rewards',
                  'NPR ${summary['gross_rewards_npr'] ?? '0'}'),
              _Metric('Available/Pending balance',
                  'NPR ${ledger['balance_npr'] ?? '0'}'),
              _Metric('Paid',
                  'NPR ${ledger['paid_npr'] ?? '0'}'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Recent attributed sales',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (purchases.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No attributed sales yet.',
                  textAlign: TextAlign.center),
            )
          else
            ...purchases.whereType<Map>().map(
                  (purchase) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(purchase['source_transaction_number']?.toString() ??
                        'Sale'),
                    subtitle: Text(
                        '${purchase['source_system']} · ${purchase['event_status']}'),
                    trailing: Text(
                      'NPR ${purchase['reward_amount_npr'] ?? '0'}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      );
}
