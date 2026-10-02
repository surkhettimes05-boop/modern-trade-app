# PASALHO customer app

Flutter Android/iOS customer commerce app for PASALHO. The app consumes the
existing customer API; it does not contain a product database or a production
fallback catalog.

## Customer flow

- Store-specific live catalog, categories, search, product details and cart
- Nepal mobile OTP authentication with secure session/CSRF storage
- Saved delivery addresses, delivery or pickup, and cash-on-delivery checkout
- Persisted idempotency key for safe order retries
- Server-confirmed order success and customer order history

## Environment configuration

Development defaults to the Android emulator host at `http://10.0.2.2:3001`.
Override it for a physical device or another development backend:

```powershell
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://192.168.1.20:3001
```

Production has no API fallback. A release build must explicitly set both the
production environment and an HTTPS API URL:

```powershell
flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.example.com
```

If production configuration is missing or not HTTPS, the app fails clearly and
does not show products. Never place secrets in Dart defines; the API URL and
public support/policy URLs are configuration, not secrets.

## Quality gates

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.example.com
```

Codemagic requires `API_BASE_URL` and the secured
`pasalho_android_signing` variable group containing
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD`. Optional `SUPPORT_PHONE`,
`PRIVACY_POLICY_URL`, and `TERMS_URL` values control customer support links.

The backend is authoritative for price, stock, fulfillment store, totals and
order creation. Cash on delivery/cash at pickup is the only enabled payment
method. Online payments and physical inventory/POS systems are outside this app.
