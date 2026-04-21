String resolveCallNotificationRoute(Map<String, dynamic> data) {
  final type = (data['type'] ?? '').toString();
  final action = (data['action'] ?? '').toString();

  if (type == 'waiting_promoted' || action == 'EMERGENCY_PROMOTION') {
    return '/call-tracking';
  }

  if (action == 'DONATION_COMPLETED' || type == 'donation_success') {
    return '/call-details';
  }

  return '/call-details';
}
