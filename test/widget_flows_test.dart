import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_trade_flutter/main.dart';
import 'package:modern_trade_flutter/models/models.dart';
import 'package:modern_trade_flutter/screens/cart_screen.dart';
import 'package:modern_trade_flutter/screens/checkout_screen.dart';
import 'package:modern_trade_flutter/screens/app_shell.dart';
import 'package:modern_trade_flutter/screens/login_screen.dart';
import 'package:modern_trade_flutter/screens/product_screen.dart';
import 'package:modern_trade_flutter/state/app_state.dart';
import 'package:modern_trade_flutter/widgets/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

const widgetProduct = Product(
    id: 'p',
    name: 'Rice',
    brand: 'PASALHO',
    category: 'Food',
    description: '',
    imageUrl: '',
    price: 100,
    availability: 'AVAILABLE');

Widget scoped(AppState state, Widget child) =>
    AppScope(notifier: state, child: MaterialApp(home: child));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('login rejects invalid Nepal phone without requesting OTP',
      (tester) async {
    final state = AppState();
    await tester.pumpWidget(scoped(state, const LoginScreen()));
    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();
    expect(find.text('Enter a valid Nepal mobile number'), findsOneWidget);
    expect(find.textContaining('Development OTP'), findsNothing);
  });

  testWidgets('unavailable product cannot be added', (tester) async {
    final state = AppState();
    const blocked = Product(
        id: 'blocked',
        name: 'Blocked item',
        brand: 'PASALHO',
        category: 'Food',
        description: '',
        imageUrl: '',
        price: 1,
        availability: 'BLOCKED');
    await tester.pumpWidget(scoped(
        state,
        const Scaffold(
            body: SizedBox(
                width: 260,
                height: 420,
                child: ProductCard(product: blocked)))));
    expect(find.widgetWithText(ElevatedButton, 'Unavailable'), findsOneWidget);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Unavailable'))
            .onPressed,
        isNull);
  });

  testWidgets('catalog failure shows PASALHO retry state with no products',
      (tester) async {
    final state = AppState()
      ..loading = false
      ..error = 'The request timed out. Please try again.';

    await tester.pumpWidget(scoped(state, const AppShell()));

    expect(find.text('Unable to connect to PASALHO'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
  });

  testWidgets('missing production configuration is distinct from connectivity',
      (tester) async {
    final state = AppState()
      ..loading = false
      ..error = 'Production API configuration is missing.';

    await tester.pumpWidget(scoped(state, const AppShell()));

    expect(find.text('PASALHO configuration error'), findsOneWidget);
    expect(find.text('Unable to connect to PASALHO'), findsNothing);
    expect(
      find.text('Production API configuration is missing.'),
      findsOneWidget,
    );
  });

  testWidgets('cart checkout requires sign in and navigates to login',
      (tester) async {
    final state = AppState()..products = const [widgetProduct];
    await state.addToCart(widgetProduct);
    await tester
        .pumpWidget(scoped(state, Scaffold(body: CartScreen(onShop: () {}))));
    await tester.tap(find.text('Continue to checkout'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('product details stay visible above basket actions on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState()..products = const [widgetProduct];
    await tester.pumpWidget(scoped(state, const ProductScreen(product: widgetProduct)));
    await tester.pumpAndSettle();
    expect(find.text('Rice').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    expect(state.cartCount, 1);
    expect(find.text('View basket').hitTestable(), findsOneWidget);
  });

  testWidgets('checkout only exposes central-warehouse delivery',
      (tester) async {
    final state = AppState()
      ..products = const [widgetProduct]
      ..customer = const Customer(id: 'customer');
    await state.addToCart(widgetProduct);
    await tester.pumpWidget(scoped(state, const CheckoutScreen()));
    await tester.scrollUntilVisible(find.text('Street, ward and locality'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Street, ward and locality'), findsOneWidget);
    expect(find.text('Pickup'), findsNothing);
    expect(find.text('Central warehouse delivery'), findsNothing);
    await tester.scrollUntilVisible(find.text('Cash on delivery'), 250,
        scrollable: find.descendant(
            of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    expect(find.text('Cash on delivery'), findsOneWidget);
  });
}
