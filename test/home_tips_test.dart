import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/screens/home_tips.dart';

void main() {
  test('selects active call tips when donor has an active call', () {
    final tip = selectHomeTip(
      now: DateTime(2026, 4, 21),
      isEligible: true,
      hasActiveCall: true,
    );

    expect(tip.category, HomeTipCategory.activeCall);
  });

  test('selects pre-donation tips for eligible donor without active call', () {
    final tip = selectHomeTip(
      now: DateTime(2026, 4, 21),
      isEligible: true,
      hasActiveCall: false,
    );

    expect(tip.category, HomeTipCategory.preDonation);
  });

  test(
    'selects post-donation tips for non-eligible donor without active call',
    () {
      final tip = selectHomeTip(
        now: DateTime(2026, 4, 21),
        isEligible: false,
        hasActiveCall: false,
      );

      expect(tip.category, HomeTipCategory.postDonation);
    },
  );
}
