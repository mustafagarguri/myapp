import 'dart:convert';

String? extractVerificationTokenFromQrRaw(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;

  try {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      final token = decoded['verification_token'];
      if (token is String && token.trim().isNotEmpty) {
        return token.trim();
      }
    }
  } catch (_) {
    // Not JSON, treat as plain token.
  }

  return value;
}

