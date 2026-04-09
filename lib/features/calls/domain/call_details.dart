import 'call_status.dart';

enum CallUiType { acceptView, waitingListView, completedView, unknown }

CallUiType callUiTypeFromApi(String? value) {
  switch (value) {
    case 'accept_view':
      return CallUiType.acceptView;
    case 'waiting_list_view':
      return CallUiType.waitingListView;
    case 'completed_view':
      return CallUiType.completedView;
    default:
      return CallUiType.unknown;
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class CallDetails {
  const CallDetails({
    required this.id,
    required this.hospitalId,
    required this.hospitalName,
    required this.bloodType,
    required this.requiredDonors,
    required this.acceptedCount,
    required this.arrivedCount,
    required this.distanceKm,
    required this.hospitalLatitude,
    required this.hospitalLongitude,
    required this.callStatus,
    required this.myStatus,
    required this.isCallFull,
    required this.uiType,
    this.commitmentExpiresAt,
  });

  final int id;
  final int hospitalId;
  final String hospitalName;
  final String bloodType;
  final int requiredDonors;
  final int acceptedCount;
  final int arrivedCount;
  final double distanceKm;
  final double hospitalLatitude;
  final double hospitalLongitude;
  final CallStatus callStatus;
  final CallStatus myStatus;
  final bool isCallFull;
  final CallUiType uiType;
  final DateTime? commitmentExpiresAt;

  bool get isFull => isCallFull || acceptedCount >= requiredDonors;

  factory CallDetails.fromBackend(Map<String, dynamic> json) {
    final call = (json['call'] as Map<String, dynamic>?) ?? json;
    final currentFilled = (call['current_filled'] as num?)?.toInt() ?? 0;
    final requiredDonors = (call['required_donors'] as num?)?.toInt() ?? 0;
    final requiredRemaining = (call['required_remaining'] as num?)?.toInt();

    return CallDetails(
      id: (call['id'] as num?)?.toInt() ?? 0,
      hospitalId: (call['hospital_id'] as num?)?.toInt() ?? 0,
      hospitalName:
          (call['hospital'] as String?) ??
          (call['hospital_name'] as String?) ??
          'مستشفى',
      bloodType: (call['blood_type'] as String?) ?? '--',
      requiredDonors: requiredDonors,
      acceptedCount: currentFilled,
      arrivedCount: (call['arrived_count'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      hospitalLatitude: _toDouble(
        call['hospital_latitude'] ?? call['hospital_lat'],
      ),
      hospitalLongitude: _toDouble(
        call['hospital_longitude'] ?? call['hospital_lng'],
      ),
      callStatus: callStatusFromApi((call['status'] as String?)?.toLowerCase()),
      myStatus: callStatusFromApi(json['donor_status'] as String?),
      isCallFull:
          (json['is_call_full'] == true) ||
          ((requiredRemaining ?? (requiredDonors - currentFilled)) <= 0),
      uiType: callUiTypeFromApi(json['ui_type'] as String?),
      commitmentExpiresAt: DateTime.tryParse(
        (json['commitment_expires_at'] as String?) ?? '',
      ),
    );
  }
}
