import 'call_status.dart';

class TrackingEntry {
  const TrackingEntry({
    required this.id,
    required this.donorName,
    required this.status,
    required this.distanceKm,
    this.respondedAt,
    this.arrivedAt,
  });

  final int id;
  final String donorName;
  final CallStatus status;
  final double distanceKm;
  final DateTime? respondedAt;
  final DateTime? arrivedAt;

  factory TrackingEntry.fromJson(Map<String, dynamic> json) {
    return TrackingEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      donorName: (json['donor_name'] as String?) ?? 'متبرع',
      status: callStatusFromApi(json['status'] as String?),
      distanceKm: (json['distance_at_response'] as num?)?.toDouble() ?? 0,
      respondedAt: DateTime.tryParse((json['responded_at'] as String?) ?? ''),
      arrivedAt: DateTime.tryParse((json['arrived_at'] as String?) ?? ''),
    );
  }
}
