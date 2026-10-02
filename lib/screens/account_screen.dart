import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../main.dart';
import 'addresses_screen.dart';
import 'info_screen.dart';
import 'login_screen.dart';
import 'loyalty_screen.dart';
import 'orders_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final customer = state.customer;
    void open(Widget screen) => Navigator.push<void>(
        context, MaterialPageRoute(builder: (_) => screen));
    return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFEAF7E3), Color(0xFFD8EDC9)]),
                  borderRadius: BorderRadius.circular(18)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                        radius: 27,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person_outline,
                            color: AppColors.brand, size: 30)),
                    const SizedBox(height: 16),
                    Text(
                        state.isSignedIn
                            ? 'Hello, ${customer?.preferredName ?? 'PASALHO customer'}'
                            : 'Your daily shop.\nYour own account.',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.8,
                            height: 1.15)),
                    const SizedBox(height: 9),
                    Text(
                        state.isSignedIn
                            ? customer?.phoneMasked ??
                                customer?.email ??
                                'Verified account'
                            : 'Sign in to save addresses, place orders and keep track of your basket.',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12, height: 1.5)),
                    if (!state.isSignedIn) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: () => open(const LoginScreen()),
                              child: const Text('Sign in with OTP')))
                    ]
                  ])),
          const SizedBox(height: 22),
          if (state.isSignedIn) ...[
            Row(children: [
              _Shortcut(
                  icon: Icons.receipt_long_outlined,
                  label: 'My orders',
                  onTap: () => open(const OrdersScreen())),
              const SizedBox(width: 10),
              _Shortcut(
                  icon: Icons.location_on_outlined,
                  label: 'Addresses',
                  onTap: () => open(const AddressesScreen())),
              const SizedBox(width: 10),
              _Shortcut(
                  icon: Icons.stars_outlined,
                  label: 'Rewards',
                  onTap: () => open(const LoyaltyScreen()))
            ]),
            const SizedBox(height: 22),
            Card(
                margin: EdgeInsets.zero,
                child: Column(children: [
                  _AccountTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'My orders',
                      subtitle: 'Track and manage your purchases',
                      onTap: () => open(const OrdersScreen())),
                  const Divider(height: 1, indent: 58),
                  _AccountTile(
                      icon: Icons.location_on_outlined,
                      title: 'Saved addresses',
                      subtitle: 'Home, work and everywhere you shop',
                      onTap: () => open(const AddressesScreen()))
                ])),
            const SizedBox(height: 18)
          ],
          const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text('Here to help',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          const _PublicLinks(),
          if (state.isSignedIn) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
                onPressed: () async {
                  await state.logout();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed out')));
                  }
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign out'))
          ],
          if (state.isDemo)
            const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Demo Build · Offline data',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.muted)))
        ]);
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
      child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
                  child: Column(children: [
                    Icon(icon, color: AppColors.brand, size: 25),
                    const SizedBox(height: 8),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700))
                  ])))));
}

class _PublicLinks extends StatelessWidget {
  const _PublicLinks();
  @override
  Widget build(BuildContext context) => Card(
        child: Column(
          children: [
            _AccountTile(
              icon: Icons.help_outline,
              title: 'Help and FAQ',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const InfoScreen(type: InfoType.help),
                ),
              ),
            ),
            const Divider(height: 1, indent: 58),
            _AccountTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy policy',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const InfoScreen(type: InfoType.privacy),
                ),
              ),
            ),
            const Divider(height: 1, indent: 58),
            _AccountTile(
              icon: Icons.description_outlined,
              title: 'Terms and conditions',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const InfoScreen(type: InfoType.terms),
                ),
              ),
            ),
          ],
        ),
      );
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.brand),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}
