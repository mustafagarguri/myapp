import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/notifications/notification_route_resolver.dart';

void main() {
  test('routes waiting list promotion notifications to tracking', () {
    expect(
      resolveCallNotificationRoute({
        'call_id': 15,
        'action': 'EMERGENCY_PROMOTION',
      }),
      '/call-tracking',
    );
  });

  test('routes donation completion notifications to call details', () {
    expect(
      resolveCallNotificationRoute({
        'call_id': 15,
        'action': 'DONATION_COMPLETED',
      }),
      '/call-details',
    );
  });

  test('keeps emergency call notifications on call details by default', () {
    expect(
      resolveCallNotificationRoute({'call_id': 15, 'type': 'emergency_call'}),
      '/call-details',
    );
  });
}
