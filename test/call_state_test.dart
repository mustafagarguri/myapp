import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/calls/data/call_api_service.dart';
import 'package:myapp/features/calls/domain/call_details.dart';
import 'package:myapp/features/calls/domain/call_status.dart';
import 'package:myapp/features/calls/presentation/call_state.dart';
import 'package:myapp/features/realtime/realtime_service.dart';

class _FakeCallApiService extends CallApiService {
  _FakeCallApiService({this.activeCallFromServer, this.callDetails});

  final CallDetails? activeCallFromServer;
  final CallDetails? callDetails;
  bool cleared = false;

  @override
  Future<CallDetails?> getActiveCallFromServer() async => activeCallFromServer;

  @override
  Future<CallDetails?> getActiveCall() async => callDetails;

  @override
  Future<CallDetails> getCallDetails(int callId) async {
    if (callDetails == null) {
      throw StateError('Missing call details for test');
    }
    return callDetails!;
  }

  @override
  Future<void> clearActiveCallId() async {
    cleared = true;
  }
}

class _FakeRealtimeService extends RealtimeService {
  bool disconnected = false;

  @override
  Future<void> connect({required int callId, required String? token}) async {}

  @override
  Future<void> disconnect() async {
    disconnected = true;
  }

  @override
  Stream<Map<String, dynamic>> get events =>
      const Stream<Map<String, dynamic>>.empty();
}

CallDetails _completedCallDetails() {
  return CallDetails.fromBackend({
    'call': {
      'id': 15,
      'hospital': 'Central Hospital',
      'hospital_id': 2,
      'hospital_lat': 32.88,
      'hospital_lng': 13.19,
      'blood_type': 'A+',
      'required_donors': 2,
      'current_filled': 2,
      'arrived_count': 2,
      'status': 'Open',
    },
    'donor_status': 'donated',
    'ui_type': 'completed_view',
    'distance_km': 1.2,
  });
}

void main() {
  test('loadActiveCall clears completed donations from active state', () async {
    final api = _FakeCallApiService(
      activeCallFromServer: _completedCallDetails(),
    );
    final realtime = _FakeRealtimeService();
    final state = CallState(api, realtime);

    await state.loadActiveCall();

    expect(state.activeCall, isNull);
    expect(api.cleared, isTrue);
    expect(realtime.disconnected, isTrue);
  });

  test(
    'loadCallDetails clears completed donations from active state',
    () async {
      final api = _FakeCallApiService(callDetails: _completedCallDetails());
      final realtime = _FakeRealtimeService();
      final state = CallState(api, realtime);

      await state.loadCallDetails(15);

      expect(state.activeCall, isNull);
      expect(api.cleared, isTrue);
      expect(realtime.disconnected, isTrue);
    },
  );

  test('maps donated status from backend payload', () {
    expect(callStatusFromApi('donated'), CallStatus.donated);
    expect(CallStatus.arrived.labelAr, 'تم الوصول');
    expect(CallStatus.donated.labelAr, 'تم التبرع');
  });
}
