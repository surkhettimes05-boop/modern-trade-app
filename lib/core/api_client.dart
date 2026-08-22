import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  String? _sessionToken;
  String? _csrfToken;

  bool get hasSession => _sessionToken?.isNotEmpty == true;

  Future<void> restoreSession() async {
    _sessionToken = await _storage.read(key: 'customer_session');
    _csrfToken = await _storage.read(key: 'customer_csrf');
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$root$path').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool mutation = false}) {
    final headers = <String, String>{
      'accept': 'application/json',
      'content-type': 'application/json',
    };
    if (_sessionToken != null) {
      final cookies = <String>['customer_session=$_sessionToken'];
      if (_csrfToken != null) cookies.add('customer_csrf=$_csrfToken');
      headers['cookie'] = cookies.join('; ');
    }
    if (mutation && _csrfToken != null) {
      headers['x-csrf-token'] = _csrfToken!;
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final response = await _client
        .get(_uri(path, query), headers: _headers())
        .timeout(const Duration(seconds: 15));
    return _decode(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await _client
        .post(
          _uri(path),
          headers: _headers(mutation: true),
          body: jsonEncode(body ?? const <String, Object?>{}),
        )
        .timeout(const Duration(seconds: 20));
    await _captureCookies(response);
    return _decode(response);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final response = await _client
        .put(
          _uri(path),
          headers: _headers(mutation: true),
          body: jsonEncode(body ?? const <String, Object?>{}),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _client
        .delete(_uri(path), headers: _headers(mutation: true))
        .timeout(const Duration(seconds: 15));
    return _decode(response);
  }

  Future<void> _captureCookies(http.Response response) async {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null) return;
    final session = RegExp(r'customer_session=([^;,]+)').firstMatch(setCookie);
    final csrf = RegExp(r'customer_csrf=([^;,]+)').firstMatch(setCookie);
    if (session != null) {
      _sessionToken = session.group(1);
      await _storage.write(key: 'customer_session', value: _sessionToken);
    }
    if (csrf != null) {
      _csrfToken = csrf.group(1);
      await _storage.write(key: 'customer_csrf', value: _csrfToken);
    }
  }

  dynamic _decode(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        data = response.body;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? data['error']?.toString() ?? data['message']?.toString()
          : null;
      throw ApiException(
        message ?? 'Request failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  Future<void> clearSession() async {
    _sessionToken = null;
    _csrfToken = null;
    await _storage.delete(key: 'customer_session');
    await _storage.delete(key: 'customer_csrf');
  }

  void close() => _client.close();
}
