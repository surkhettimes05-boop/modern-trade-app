import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

// Browsers manage HttpOnly session cookies; include them across API origins.
http.Client createHttpClient() => BrowserClient()..withCredentials = true;
String? browserCsrfToken() {
  final match =
      RegExp(r'(?:^|; )customer_csrf=([^;]+)').firstMatch(web.document.cookie);
  return match == null ? null : Uri.decodeComponent(match.group(1)!);
}
