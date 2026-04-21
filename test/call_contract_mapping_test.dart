import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/calls/domain/call_details.dart';
import 'package:myapp/features/calls/domain/tracking_entry.dart';

void main() {
  test('maps tracking and in-hospital ui types from backend payload', () {
    final trackingCall = CallDetails.fromBackend({
      'call': {
        'id': 12,
        'hospital': 'City Hospital',
        'hospital_lat': '32.8872',
        'hospital_lng': '13.1913',
        'blood_type': 'A+',
        'required_donors': 3,
        'current_filled': 1,
        'arrived_count': 0,
        'status': 'Open',
      },
      'donor_status': 'accepted',
      'ui_type': 'tracking_view',
      'distance_km': '4.5',
      'commitment_expires_at': '2026-04-20T18:30:00Z',
    });

    final inHospitalCall = CallDetails.fromBackend({
      'call': {
        'id': 13,
        'hospital': 'City Hospital',
        'hospital_lat': 32.8872,
        'hospital_lng': 13.1913,
        'blood_type': 'A+',
        'required_donors': 3,
        'current_filled': 2,
        'arrived_count': 1,
        'status': 'Completed',
      },
      'donor_status': 'arrived',
      'ui_type': 'in_hospital',
      'distance_km': 1.2,
    });

    expect(trackingCall.uiType, CallUiType.trackingView);
    expect(trackingCall.distanceKm, 4.5);
    expect(trackingCall.hospitalLatitude, 32.8872);
    expect(trackingCall.commitmentExpiresAt, isNotNull);

    expect(inHospitalCall.uiType, CallUiType.inHospital);
    expect(inHospitalCall.arrivedCount, 1);
  });

  test(
    'tracking entry accepts both distance_at_response and distance fields',
    () {
      final primary = TrackingEntry.fromJson({
        'id': 1,
        'donor_name': 'Ali',
        'status': 'accepted',
        'distance_at_response': '3.7',
        'responded_at': '2026-04-20T17:00:00Z',
      });

      final fallback = TrackingEntry.fromJson({
        'id': 2,
        'donor_name': 'Mona',
        'status': 'waiting_list',
        'distance': 5.4,
      });

      expect(primary.distanceKm, 3.7);
      expect(primary.respondedAt, isNotNull);
      expect(fallback.distanceKm, 5.4);
    },
  );
}
