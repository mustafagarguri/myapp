import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/screens/donation_history_screen.dart';

void main() {
  test('DonationLedgerEntry parses backend donation_date payload', () {
    final entry = DonationLedgerEntry.fromJson({
      'id': 12,
      'call_id': 34,
      'hospital_name': 'Tripoli Central',
      'blood_type': 'A+',
      'donation_date': '2026-04-20',
    });

    expect(entry.callId, 34);
    expect(entry.hospitalName, 'Tripoli Central');
    expect(entry.bloodType, 'A+');
    expect(entry.donatedAt, isNotNull);
    expect(entry.donatedAt!.year, 2026);
    expect(entry.donatedAt!.month, 4);
    expect(entry.donatedAt!.day, 20);
  });

  test('DonationLedgerEntry falls back to id when call_id is missing', () {
    final entry = DonationLedgerEntry.fromJson({
      'id': 12,
      'hospital_name': 'Tripoli Central',
      'blood_type': 'O-',
      'donated_at': '2026-04-19',
    });

    expect(entry.callId, 12);
    expect(entry.donatedAt, isNotNull);
  });
}
