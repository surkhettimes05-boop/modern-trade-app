import '../core/api_client.dart';
import '../models/models.dart';

class GoogleLoginResult {
  const GoogleLoginResult({
    this.customer,
    this.linkToken,
    this.email,
  });

  final Customer? customer;
  final String? linkToken;
  final String? email;

  bool get linkRequired => linkToken?.isNotEmpty == true;
}

class AuthRepository {
  AuthRepository(this.api);
  final ApiClient api;

  Future<void> requestOtp(String phone) async {
    await api.post('/api/auth/otp/request',
        body: {'phone': phone, 'purpose': 'LOGIN'});
    // Deliberately ignore any server-returned OTP. An OTP must only reach the user out of band.
  }

  Future<Customer> verifyOtp(String phone, String code) async {
    final response = await api.post('/api/auth/otp/verify',
        body: {'phone': phone, 'otp_code': code, 'purpose': 'LOGIN'});
    return _customerFromResponse(response);
  }

  Future<GoogleLoginResult> googleLogin(String idToken) async {
    final response =
        await api.post('/api/auth/google', body: {'id_token': idToken});
    if (response is! Map) {
      throw const ApiException(
        'Google sign-in returned an invalid response.',
        kind: ApiErrorKind.invalidResponse,
      );
    }

    if (response['link_required'] == true) {
      final token = response['link_token']?.toString() ?? '';
      final profile = response['google_profile'];
      final email = profile is Map ? profile['email']?.toString() : null;
      if (token.isEmpty) {
        throw const ApiException(
          'Google sign-in could not be linked. Please try again.',
          kind: ApiErrorKind.invalidResponse,
        );
      }
      return GoogleLoginResult(linkToken: token, email: email);
    }

    return GoogleLoginResult(customer: _customerFromResponse(response));
  }

  Future<Customer> linkGoogle({
    required String linkToken,
    required String phone,
    required String code,
  }) async {
    final response = await api.post('/api/auth/google/link', body: {
      'link_token': linkToken,
      'phone': phone,
      'otp_code': code,
    });
    return _customerFromResponse(response);
  }

  Future<Customer?> validateSession() async {
    final response = await api.get('/api/auth/session/validate');
    if (response is Map && response['customer'] is Map) {
      return Customer.fromJson(
          Map<String, dynamic>.from(response['customer'] as Map));
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await api.post('/api/auth/logout');
    } finally {
      await api.clearSession();
    }
  }

  Customer _customerFromResponse(dynamic response) {
    if (response is! Map || response['customer'] is! Map) {
      throw const ApiException(
        'We could not sign you in. Please try again.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
    return Customer.fromJson(
        Map<String, dynamic>.from(response['customer'] as Map));
  }
}
