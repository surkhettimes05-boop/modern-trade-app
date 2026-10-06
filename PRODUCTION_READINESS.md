# Flutter Nepal COD readiness — 2026-10-06

Status: NOT READY pending runtime tests, signed build and live OTP/COD proof.

Deploy the paired modern-trade-website backend branch first. This app now requires:
- GET /api/checkout/service-areas?store_id=<uuid>
- POST /api/checkout/delivery-quote with store_id, municipality_id, ward_id, order_value
- PUT /api/shopping-cart/:cartId/items with {items:[{product_id,quantity}]}
- POST /api/checkout/cod with server cart/store IDs, persistent idempotency key,
  shipping_name/phone and delivery_type. DELIVERY additionally sends street,
  shipping_municipality_id, shipping_ward_id, postal code and shipping_country=NP.
  PICKUP omits delivery-only fields. No customer ID, price or discount is submitted.

Changes:
- lib/repositories/checkout_repository.dart: strict Nepal delivery contract, area/
  quote requests and atomic retry-safe cart replacement. Checkout attempt storage
  moves to v2 so incomplete legacy additive uploads are not reused.
- lib/screens/checkout_screen.dart: municipality/ward choices from active backend
  zones, serviceability gate, displayed delivery fee and total, five-digit postal
  validation and safe async error handling.
- lib/state/app_state.dart: passes municipality/ward IDs to checkout.
- test/checkout_repository_test.dart: updated contract assertions and retry tests.
- test/app_state_test.dart: updated checkout call signature.
- test/widget_flows_test.dart: isolates area loading from live network in checkout UI test.

Verification: Dart formatting parsed the changed files before Flutter execution was
blocked. Automated approval review rejected Flutter startup after a cloud metadata
endpoint access; no bypass or successful Flutter test/analyze/build is claimed.
Run the existing Codemagic analyze, test and signed build gates on this exact branch.

Set API_BASE_URL=https://<backend>.onrender.com (no /api suffix). Native secure
storage retains session/CSRF cookies; mutations send x-csrf-token. Supply signing
secrets, SUPPORT_PHONE, PRIVACY_POLICY_URL and TERMS_URL through Codemagic.

Test delivery and pickup, incorrect/reused OTP, no-service wards, lost upload
response, lost checkout response, retry returning one order, order history,
cancellation and logout. Real staff cash collection must be tested end to end.
For demo versus Twilio and exact Render/Vercel setup, use PRODUCTION_READINESS.md in
the website repository. Demo is allowed only on an isolated non-production backend;
production Twilio requires real Nepal SMS evidence. Electronic payments, returns,
promotions and offline sync remain disabled.

## CI follow-up — 2026-10-07

Added .github/workflows/flutter-quality.yml to verify this separate app on draft
pull requests: dependency install, Dart syntax, analysis, tests and debug APK compile.
It does not deploy the app or use signing/provider secrets. Codemagic remains the
signed release build gate. Workflow results must be recorded before certification.
