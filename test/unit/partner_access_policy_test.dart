import 'package:cyclecare/features/partner/domain/partner_access_policy.dart';
import 'package:cyclecare/features/partner/application/partner_sharing_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new sharing starts without permission to disclose health fields', () {
    const options = PartnerSharingOptions();
    expect(options.sharePhase, isFalse);
    expect(options.shareNextPeriod, isFalse);
    expect(options.shareSupportTip, isFalse);
  });

  test('partner settings are independent of owner page permissions', () {
    const policy = PartnerAccessPolicy();
    expect(policy.canView(PartnerPage.settings), isTrue);
    expect(policy.canView(PartnerPage.home), isFalse);
    expect(policy.canView(PartnerPage.calendar), isFalse);
  });

  test('revocation overrides all shared page grants', () {
    const policy = PartnerAccessPolicy(home: true, calendar: true, revoked: true);
    expect(policy.canView(PartnerPage.home), isFalse);
    expect(policy.canView(PartnerPage.calendar), isFalse);
    expect(policy.canView(PartnerPage.settings), isTrue);
  });

  test('permissions round trip and missing grants deny access', () {
    final policy = PartnerAccessPolicy.fromJson({'home': true});
    expect(policy.canView(PartnerPage.home), isTrue);
    expect(policy.canView(PartnerPage.calendar), isFalse);
    final restored = PartnerAccessPolicy.fromJson(policy.toJson());
    expect(restored.toJson(), policy.toJson());
    expect(() => PartnerAccessPolicy.fromJson({'calendar': 'true'}),
        throwsFormatException);
  });
}
