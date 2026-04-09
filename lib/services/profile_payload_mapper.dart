class ProfilePayloadMapper {
  const ProfilePayloadMapper._();

  static ProfileData mapResponse(Map<String, dynamic> response) {
    final user = _extractUser(response);
    final bloodType = _asMap(user['blood_type']);

    return ProfileData(
      firstName: _asString(user['first_name']) ?? '',
      lastName: _asString(user['last_name']) ?? '',
      email: _asString(user['email']) ?? '',
      phoneNumber: _asString(user['phone_number']) ?? '',
      weightText: _asString(user['weight']) ?? '',
      bloodTypeId: _asInt(bloodType?['id']) ?? _asInt(user['blood_type_id']),
      bloodTypeName:
          _asString(bloodType?['name']) ?? _asString(user['blood_type']) ?? '--',
      isAvailable: _asBool(user['is_available']) ?? false,
      dateOfBirth: _parseDate(user['date_of_birth']),
      nextEligibleDate: _parseDate(user['next_eligible_date']),
    );
  }

  static Map<String, dynamic> _extractUser(Map<String, dynamic> response) {
    final user = _asMap(response['user']);
    if (user != null) return user;

    final data = _asMap(response['data']);
    if (data != null) {
      final nestedUser = _asMap(data['user']);
      if (nestedUser != null) return nestedUser;
      return data;
    }

    return Map<String, dynamic>.from(response);
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, entryValue) => MapEntry('$key', entryValue));
    }
    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    return value is String ? value : '$value';
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    final raw = _asString(value);
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class ProfileData {
  const ProfileData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.weightText,
    required this.bloodTypeName,
    required this.isAvailable,
    this.bloodTypeId,
    this.dateOfBirth,
    this.nextEligibleDate,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String weightText;
  final int? bloodTypeId;
  final String bloodTypeName;
  final bool isAvailable;
  final DateTime? dateOfBirth;
  final DateTime? nextEligibleDate;
}
