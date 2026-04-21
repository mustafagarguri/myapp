import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../services/api_service.dart';
import '../domain/call_details.dart';
import '../domain/call_status.dart';
import '../domain/tracking_entry.dart';
import 'call_endpoints.dart';
import 'call_local_store.dart';

class CallApiService {
  CallApiService({CallLocalStore? localStore})
    : _localStore = localStore ?? CallLocalStore();

  static const Duration _timeout = Duration(seconds: 15);
  final CallLocalStore _localStore;

  Map<String, String> _headers({bool requiresAuth = true}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (requiresAuth && ApiService.token != null)
        'Authorization': 'Bearer ${ApiService.token}',
    };
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('${ApiService.baseUrl}$endpoint');
    final encodedBody = body == null ? null : jsonEncode(body);

    try {
      late http.Response response;
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: _headers()).timeout(_timeout);
          break;
        case 'POST':
          response = await http
              .post(url, headers: _headers(), body: encodedBody)
              .timeout(_timeout);
          break;
        default:
          throw const ApiException('طريقة الطلب غير مدعومة');
      }

      final payload = _safeDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return payload;
      }

      throw ApiException(
        _extractError(payload, response.statusCode),
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw const ApiException('تعذر الاتصال بالخادم');
    }
  }

  Map<String, dynamic> _safeDecode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) return parsed;
      return {'data': parsed};
    } catch (_) {
      return {'message': body};
    }
  }

  String _extractError(Map<String, dynamic> payload, int status) {
    final message = payload['message'];
    if (message is String && message.isNotEmpty) return message;
    return 'فشل الطلب برمز الحالة $status';
  }

  Future<void> saveActiveCallId(int callId) =>
      _localStore.saveActiveCallId(callId);

  Future<void> clearActiveCallId() => _localStore.clearActiveCallId();

  Future<CallDetails?> getActiveCall() async {
    final callId = await _localStore.getActiveCallId();
    if (callId == null || callId <= 0) return null;

    try {
      final details = await getCallDetails(callId);
      if (_isResolvedCall(details)) {
        await _localStore.clearActiveCallId();
        return null;
      }
      return details;
    } catch (_) {
      return null;
    }
  }

  Future<CallDetails?> getActiveCallFromServer() async {
    try {
      final response = await _request(
        method: 'GET',
        endpoint: CallEndpoints.activeCall,
      );
      final details = CallDetails.fromBackend(response);
      if (_isResolvedCall(details)) {
        await _localStore.clearActiveCallId();
        return null;
      }
      if (details.id > 0) {
        await _localStore.saveActiveCallId(details.id);
        return details;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CallDetails> getCallDetails(int callId) async {
    final response = await _request(
      method: 'GET',
      endpoint: CallEndpoints.callDetails(callId),
    );
    final details = CallDetails.fromBackend(response);
    await _localStore.saveActiveCallId(details.id);
    return details;
  }

  Future<void> respondToCall(int callId, CallStatus status) async {
    double? lat;
    double? lng;

    try {
      final p = await Geolocator.getCurrentPosition();
      lat = p.latitude;
      lng = p.longitude;
    } catch (_) {
      // Keep request valid even when location is unavailable.
    }

    final response = await _request(
      method: 'POST',
      endpoint: CallEndpoints.respond,
      body: {
        'call_id': callId,
        'status': status.apiValue,
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
      },
    );

    final returnedStatus = callStatusFromApi((response['status'] as String?));
    if (returnedStatus == CallStatus.rejected ||
        returnedStatus == CallStatus.expired) {
      await _localStore.clearActiveCallId();
    } else {
      await _localStore.saveActiveCallId(callId);
    }
  }

  Future<void> cancelCommitment(int callId, {String? reason}) async {
    await _request(
      method: 'POST',
      endpoint: CallEndpoints.cancelAttendance,
      body: {
        'call_id': callId,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );

    await _localStore.clearActiveCallId();
  }

  Future<void> verifyArrivalByQr({
    required int callId,
    required String token,
  }) async {
    if (callId <= 0) {
      throw const ApiException('معرف النداء غير صالح.');
    }

    final value = token.trim();
    if (value.isEmpty) {
      throw const ApiException('رمز التحقق فارغ.');
    }

    await _request(
      method: 'POST',
      endpoint: CallEndpoints.verifyArrival,
      body: {'verification_token': value},
    );
  }

  Future<List<TrackingEntry>> getCallTracking(int callId) async {
    // Keep parsing tolerant while the backend response is standardized.
    final response = await _request(
      method: 'GET',
      endpoint: CallEndpoints.callTracking(callId),
    );

    final raw = response['tracking'] ?? response['data'] ?? response['entries'];
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map(TrackingEntry.fromJson)
        .toList();
  }

  bool _isResolvedCall(CallDetails details) {
    return details.uiType == CallUiType.completedView ||
        details.myStatus == CallStatus.donated;
  }
}
