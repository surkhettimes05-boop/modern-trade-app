class AppConfig {
  static const maxCartQuantity =
      int.fromEnvironment('MAX_CART_QUANTITY', defaultValue: 99);
  static const supportPhone = String.fromEnvironment('SUPPORT_PHONE');
  static const privacyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
  static const termsUrl = String.fromEnvironment('TERMS_URL');
  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
}
