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

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }
    return 0;
  }

  static double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static String? _toNonEmptyString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  factory TrackingEntry.fromJson(Map<String, dynamic> json) {
    return TrackingEntry(
      id: _toInt(json['id']),
      donorName: _toNonEmptyString(json['donor_name']) ?? 'متبرع',
      status: callStatusFromApi(_toNonEmptyString(json['status'])),
      distanceKm: _toDouble(json['distance_at_response']),
      respondedAt: DateTime.tryParse(
        _toNonEmptyString(json['responded_at']) ?? '',
      ),
      arrivedAt: DateTime.tryParse(_toNonEmptyString(json['arrived_at']) ?? ''),
    );
  }
}
