/// Page grants for a connected partner, separate from health-field consent.
/// This is a client-side presentation policy, not a substitute for server
/// authorization. A server must filter every response using current grants.
enum PartnerPage { home, calendar, settings }

class PartnerAccessPolicy {
  const PartnerAccessPolicy({
    this.home = false,
    this.calendar = false,
    this.revoked = false,
  });

  final bool home;
  final bool calendar;
  final bool revoked;

  /// Settings belong to the partner: disconnecting and changing their own
  /// preferences must remain possible after the owner withdraws access.
  bool canView(PartnerPage page) => switch (page) {
        PartnerPage.settings => true,
        PartnerPage.home => !revoked && home,
        PartnerPage.calendar => !revoked && calendar,
      };

  Map<String, dynamic> toJson() => {
        'home': home,
        'calendar': calendar,
        'revoked': revoked,
      };

  factory PartnerAccessPolicy.fromJson(Map<String, dynamic> json) {
    bool grant(String key) {
      final value = json[key];
      if (value == null) return false;
      if (value is! bool) {
        throw FormatException('Invalid partner permission: $key');
      }
      return value;
    }

    return PartnerAccessPolicy(
      home: grant('home'),
      calendar: grant('calendar'),
      revoked: grant('revoked'),
    );
  }
}
