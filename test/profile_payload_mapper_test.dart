import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/services/profile_payload_mapper.dart';

void main() {
  test('maps numeric phone number safely', () {
    final profile = ProfilePayloadMapper.mapResponse({
      'user': {
        'first_name': 'Ali',
        'last_name': 'Saleh',
        'phone_number': 912345678,
        'weight': 72.5,
        'blood_type': {'id': 5, 'name': 'O+'},
        'date_of_birth': '1990-05-12',
        'next_eligible_date': '2026-06-01',
        'is_available': true,
      },
    });

    expect(profile.phoneNumber, '912345678');
    expect(profile.weightText, '72.5');
    expect(profile.bloodTypeId, 5);
    expect(profile.bloodTypeName, 'O+');
    expect(profile.dateOfBirth, DateTime(1990, 5, 12));
    expect(profile.nextEligibleDate, DateTime(2026, 6, 1));
    expect(profile.isAvailable, isTrue);
  });

  test('maps string phone number without changes', () {
    final profile = ProfilePayloadMapper.mapResponse({
      'user': {
        'phone_number': '0912345678',
      },
    });

    expect(profile.phoneNumber, '0912345678');
  });

  test('falls back to blood_type_id when relation is not loaded', () {
    final profile = ProfilePayloadMapper.mapResponse({
      'user': {
        'blood_type_id': 7,
        'blood_type': 'AB+',
      },
    });

    expect(profile.bloodTypeId, 7);
    expect(profile.bloodTypeName, 'AB+');
  });

  test('extracts nested data.user payload', () {
    final profile = ProfilePayloadMapper.mapResponse({
      'data': {
        'user': {
          'first_name': 'Mona',
          'last_name': 'Ali',
          'phone_number': 987654321,
        },
      },
    });

    expect(profile.firstName, 'Mona');
    expect(profile.lastName, 'Ali');
    expect(profile.phoneNumber, '987654321');
  });

  test('keeps null email and invalid date as safe defaults', () {
    final profile = ProfilePayloadMapper.mapResponse({
      'user': {
        'email': null,
        'date_of_birth': null,
      },
    });

    expect(profile.email, '');
    expect(profile.dateOfBirth, isNull);
  });
}
