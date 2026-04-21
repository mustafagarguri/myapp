import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../app/blood_type_options.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  // رابط API الافتراضي لبيئة Laravel المحلية (Android Emulator).
  static const String _defaultBaseUrl = 'http://10.0.2.2:8000/api';
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const String _pendingLatitudeKey = 'pending_latitude';
  static const String _pendingLongitudeKey = 'pending_longitude';

  static String get baseUrl {
    final fromDefine = const String.fromEnvironment('API_BASE_URL');
    return fromDefine.isNotEmpty ? fromDefine : _defaultBaseUrl;
  }

  static String? _token;
  static String? get token => _token;

  static Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    _token = token;
  }

  static Future<void> _savePendingLocation({
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pendingLatitudeKey, latitude);
    await prefs.setDouble(_pendingLongitudeKey, longitude);
  }

  static Future<void> _clearPendingLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingLatitudeKey);
    await prefs.remove(_pendingLongitudeKey);
  }

  static Future<void> logout() async {
    if (_token != null) {
      try {
        await _request(method: 'POST', endpoint: '/logout', requiresAuth: true);
      } catch (_) {
        // نضمن تنظيف التوكن محلياً حتى لو فشل الخروج من السيرفر.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
  }

  static Map<String, String> _headers({bool requiresAuth = false}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (requiresAuth && _token != null) 'Authorization': 'Bearer $_token',
    };
  }

  static Future<Map<String, dynamic>> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final encodedBody = body == null ? null : jsonEncode(body);

    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http
              .get(url, headers: _headers(requiresAuth: requiresAuth))
              .timeout(_requestTimeout);
          break;
        case 'POST':
          response = await http
              .post(
                url,
                headers: _headers(requiresAuth: requiresAuth),
                body: encodedBody,
              )
              .timeout(_requestTimeout);
          break;
        case 'PUT':
          response = await http
              .put(
                url,
                headers: _headers(requiresAuth: requiresAuth),
                body: encodedBody,
              )
              .timeout(_requestTimeout);
          break;
        case 'PATCH':
          response = await http
              .patch(
                url,
                headers: _headers(requiresAuth: requiresAuth),
                body: encodedBody,
              )
              .timeout(_requestTimeout);
          break;
        default:
          throw const ApiException('طريقة طلب غير مدعومة');
      }
    } catch (_) {
      throw const ApiException('خطأ في الشبكة. يرجى التحقق من اتصال الإنترنت.');
    }

    final parsed = _safeDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parsed;
    }

    final message = _extractErrorMessage(parsed, response.statusCode);
    throw ApiException(message, statusCode: response.statusCode);
  }

  static Map<String, dynamic> _safeDecode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'data': decoded};
    } catch (_) {
      return <String, dynamic>{'message': body};
    }
  }

  static String _extractErrorMessage(Map<String, dynamic> payload, int status) {
    final message = payload['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    final errors = payload['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String) return first;
        }
      }
    }

    return 'فشل الطلب برمز الحالة $status';
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final data = await _request(
      method: 'POST',
      endpoint: '/login',
      body: {'email': email, 'password': password},
    );

    final token = data['data']?['token'] ?? data['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('رمز الدخول غير موجود في الاستجابة.');
    }

    await _saveToken(token);
    return data;
  }

  static Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required int bloodTypeId,
    required double weight,
    required DateTime dateOfBirth,
    double? height,
    String? gender,
    String? lastDonationDate,
  }) async {
    final bloodType = bloodTypeOptions[bloodTypeId];
    if (bloodType == null) {
      throw const ApiException('فصيلة الدم المحددة غير صالحة.');
    }

    final y = dateOfBirth.year.toString().padLeft(4, '0');
    final m = dateOfBirth.month.toString().padLeft(2, '0');
    final d = dateOfBirth.day.toString().padLeft(2, '0');

    final body = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'password': password,
      'blood_type': bloodType,
      'weight': weight,
      'date_of_birth': '$y-$m-$d',
      if (height != null) 'height': height,
      if (gender != null && gender.trim().isNotEmpty) 'gender': gender,
      if (lastDonationDate != null) 'last_donation_date': lastDonationDate,
    };

    final data = await _request(
      method: 'POST',
      endpoint: '/register',
      body: body,
    );

    return data;
  }

  static Future<Map<String, dynamic>> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    final data = await _request(
      method: 'POST',
      endpoint: '/register/verify-otp',
      body: {'email': email, 'otp': otp},
    );

    final token = data['data']?['token'] ?? data['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('رمز الدخول غير موجود بعد تأكيد الحساب.');
    }

    await _saveToken(token);
    return data;
  }

  static Future<Map<String, dynamic>> resendRegistrationOtp(String email) {
    return _request(
      method: 'POST',
      endpoint: '/register/resend-otp',
      body: {'email': email},
    );
  }

  static Future<Map<String, dynamic>> getUserProfile() {
    return _request(
      method: 'GET',
      endpoint: '/user/profile',
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required double weight,
    required int bloodTypeId,
    required DateTime dateOfBirth,
  }) {
    final bloodType = bloodTypeOptions[bloodTypeId];
    if (bloodType == null) {
      throw const ApiException('فصيلة الدم المحددة غير صالحة.');
    }

    final y = dateOfBirth.year.toString().padLeft(4, '0');
    final m = dateOfBirth.month.toString().padLeft(2, '0');
    final d = dateOfBirth.day.toString().padLeft(2, '0');

    final body = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'weight': weight,
      'blood_type': bloodType,
      'date_of_birth': '$y-$m-$d',
    };

    return _request(
      method: 'PUT',
      endpoint: '/user/profile',
      body: body,
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> updateLocation({
    required double latitude,
    required double longitude,
  }) {
    return _request(
      method: 'PATCH',
      endpoint: '/user/location',
      body: {'latitude': latitude, 'longitude': longitude},
      requiresAuth: true,
    );
  }

  static Future<void> queuePendingLocation({
    required double latitude,
    required double longitude,
  }) {
    return _savePendingLocation(latitude: latitude, longitude: longitude);
  }

  static Future<bool> flushPendingLocation() async {
    if (_token == null || _token!.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_pendingLatitudeKey);
    final longitude = prefs.getDouble(_pendingLongitudeKey);
    if (latitude == null || longitude == null) return false;

    await updateLocation(latitude: latitude, longitude: longitude);
    await _clearPendingLocation();
    return true;
  }

  static Future<Map<String, dynamic>> updateFcmToken(String fcmToken) {
    return _request(
      method: 'PATCH',
      endpoint: '/profile/fcm-token',
      body: {'fcm_token': fcmToken},
      requiresAuth: true,
    );
  }

  static Future<List<Map<String, dynamic>>> getDonationLedger() async {
    final response = await _request(
      method: 'GET',
      endpoint: '/donor/ledger',
      requiresAuth: true,
    );

    final raw = response['data'] ?? response['ledger'] ?? response['donations'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }

    return const [];
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _request(
      method: 'POST',
      endpoint: '/password/forgot',
      body: {'email': email},
    );
  }

  static Future<Map<String, dynamic>> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) {
    return _request(
      method: 'POST',
      endpoint: '/password/verify-otp',
      body: {'email': email, 'otp': otp},
    );
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    return _request(
      method: 'POST',
      endpoint: '/password/reset',
      body: {
        'email': email,
        'reset_token': resetToken,
        'password': newPassword,
        'password_confirmation': passwordConfirmation,
      },
    );
  }
}
