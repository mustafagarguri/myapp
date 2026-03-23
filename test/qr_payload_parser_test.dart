import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/calls/domain/qr_payload_parser.dart';

void main() {
  test('parses plain token value', () {
    expect(extractVerificationTokenFromQrRaw('abc123'), 'abc123');
  });

  test('parses token from JSON payload', () {
    const raw = '{"verification_token":"token_xyz"}';
    expect(extractVerificationTokenFromQrRaw(raw), 'token_xyz');
  });

  test('returns null for empty payload', () {
    expect(extractVerificationTokenFromQrRaw('  '), isNull);
  });
}

