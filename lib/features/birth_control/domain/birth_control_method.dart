// ─────────────────────────────────────────────────────────────────────────────
// Birth control method catalogue
//
// Copy in this file is deliberately descriptive, never instructional. Each
// entry says what a method is and the rhythm it is normally used on, and stops
// there. No dosages, no effectiveness figures, no "take this then that".
// Anything that could change how someone uses their own contraception belongs
// to the leaflet in the box and to their clinician — a tracker is the wrong
// place for it, and being confidently wrong here has real consequences.
//
// Enum *names* are persisted under the existing method preferences key, so the
// original eight spellings are untouched. Newer methods are appended, and the
// declaration order below is also the order the picker renders.
// ─────────────────────────────────────────────────────────────────────────────

/// How the picker groups methods. Grouping matters more than it sounds: a flat
/// list of eleven options reads as a wall, whereas four short groups let
/// someone find their own method by category in one pass.
enum MethodGroup {
  dailyPill('Daily pills'),
  scheduled('Weekly and monthly'),
  longActing('Fitted or injected'),
  barrierAndOther('Barrier, awareness and other'),
  unset('Not tracking a method');

  const MethodGroup(this.label);

  final String label;
}

enum BirthControlMethod {
  // ── Daily pills ───────────────────────────────────────────────────────────
  pill,
  progestinPill,

  // ── Weekly / monthly ──────────────────────────────────────────────────────
  patch,
  ring,

  // ── Fitted or injected ────────────────────────────────────────────────────
  iud,
  copperIud,
  implant,
  injection,

  // ── Barrier, awareness, other ─────────────────────────────────────────────
  condom,
  naturalFam,
  other,

  // ── Nothing recorded ──────────────────────────────────────────────────────
  none;

  String get label => switch (this) {
        BirthControlMethod.pill => 'Combination pill',
        BirthControlMethod.progestinPill => 'Progestin-only pill',
        BirthControlMethod.patch => 'Patch',
        BirthControlMethod.ring => 'Vaginal ring',
        BirthControlMethod.iud => 'Hormonal IUD',
        BirthControlMethod.copperIud => 'Copper IUD',
        BirthControlMethod.implant => 'Implant',
        BirthControlMethod.injection => 'Injection',
        BirthControlMethod.condom => 'Condoms',
        BirthControlMethod.naturalFam => 'Natural / FAM',
        BirthControlMethod.other => 'Other method',
        BirthControlMethod.none => 'Not tracking',
      };

  /// Shorter label for tight spaces — chips, the app bar subtitle, the hero.
  String get shortLabel => switch (this) {
        BirthControlMethod.pill => 'Combination pill',
        BirthControlMethod.progestinPill => 'Mini-pill',
        BirthControlMethod.naturalFam => 'FAM',
        BirthControlMethod.other => 'Other',
        BirthControlMethod.none => 'Not tracking',
        _ => label,
      };

  String get emoji => switch (this) {
        BirthControlMethod.pill => '💊',
        BirthControlMethod.progestinPill => '🌙',
        BirthControlMethod.patch => '🩹',
        BirthControlMethod.ring => '💍',
        BirthControlMethod.iud => '🩺',
        BirthControlMethod.copperIud => '🧲',
        BirthControlMethod.implant => '💠',
        BirthControlMethod.injection => '💉',
        BirthControlMethod.condom => '🛡️',
        BirthControlMethod.naturalFam => '🌡️',
        BirthControlMethod.other => '🧩',
        BirthControlMethod.none => '➖',
      };

  MethodGroup get group => switch (this) {
        BirthControlMethod.pill ||
        BirthControlMethod.progestinPill =>
          MethodGroup.dailyPill,
        BirthControlMethod.patch ||
        BirthControlMethod.ring =>
          MethodGroup.scheduled,
        BirthControlMethod.iud ||
        BirthControlMethod.copperIud ||
        BirthControlMethod.implant ||
        BirthControlMethod.injection =>
          MethodGroup.longActing,
        BirthControlMethod.condom ||
        BirthControlMethod.naturalFam ||
        BirthControlMethod.other =>
          MethodGroup.barrierAndOther,
        BirthControlMethod.none => MethodGroup.unset,
      };

  /// What the method is. Descriptive only.
  String get summary => switch (this) {
        BirthControlMethod.pill =>
          'A pill containing both an oestrogen and a progestin. Often called '
              'the combined pill.',
        BirthControlMethod.progestinPill =>
          'A pill containing a progestin and no oestrogen. Often called the '
              'mini-pill or POP.',
        BirthControlMethod.patch =>
          'An adhesive patch worn on the skin that releases hormones through '
              'it.',
        BirthControlMethod.ring =>
          'A soft, flexible ring placed in the vagina that releases hormones '
              'while it is in place.',
        BirthControlMethod.iud =>
          'A small device fitted inside the uterus that releases a progestin '
              'locally. Also called a hormonal coil or IUS.',
        BirthControlMethod.copperIud =>
          'A small device fitted inside the uterus that works through copper '
              'rather than hormones. Also called the copper coil.',
        BirthControlMethod.implant =>
          'A thin rod placed under the skin of the upper arm that releases a '
              'progestin.',
        BirthControlMethod.injection =>
          'A progestin injection. Some products are given by a clinician, '
              'others are designed for use at home.',
        BirthControlMethod.condom =>
          'A barrier used during sex. External and internal versions exist, '
              'and they are also used as a barrier against sexually '
              'transmitted infections.',
        BirthControlMethod.naturalFam =>
          'Fertility awareness methods read body signs — basal temperature, '
              'cervical mucus, cycle length — to identify fertile days. '
              'Several distinct systems exist.',
        BirthControlMethod.other =>
          'Covers sterilisation, diaphragms and caps, spermicides, emergency '
              'contraception and anything else not listed here.',
        BirthControlMethod.none =>
          'Nothing recorded. A pharmacist or clinician can talk through what '
              'is available where you live.',
      };

  /// The rhythm the method runs on — how it is taken, changed or replaced.
  /// Phrased as what typically happens, not as an instruction.
  String get routine => switch (this) {
        BirthControlMethod.pill =>
          'One pill a day. Packs are commonly laid out as 21 active days with '
              '7 placebo or break days, or 24 active with 4 — the pack itself '
              'says which.',
        BirthControlMethod.progestinPill =>
          'One pill a day. Most packs are active every day, with no break '
              'week built in.',
        BirthControlMethod.patch =>
          'Changed on a weekly rhythm in most regimens, often with a '
              'patch-free week. The product leaflet sets out the pattern.',
        BirthControlMethod.ring =>
          'Worn continuously for a stretch of weeks, then removed for a '
              'ring-free stretch, or replaced monthly, depending on the '
              'product.',
        BirthControlMethod.iud =>
          'Fitted and removed by a trained clinician. It stays in place for '
              'several years, and the exact interval depends on the brand.',
        BirthControlMethod.copperIud =>
          'Fitted and removed by a trained clinician. It stays in place for '
              'several years, and the exact interval depends on the type.',
        BirthControlMethod.implant =>
          'Inserted and removed by a trained clinician, and replaced after a '
              'set number of years that varies by product.',
        BirthControlMethod.injection =>
          'Repeated at the interval set out in the product information, '
              'commonly measured in months rather than weeks.',
        BirthControlMethod.condom =>
          'Single use — a new one each time. Nothing to track between times.',
        BirthControlMethod.naturalFam =>
          'Daily observations, recorded and read against the rules of '
              'whichever method is being followed.',
        BirthControlMethod.other =>
          'Depends entirely on the specific method. Some are one-off, some '
              'are per-use, some are replaced on a schedule.',
        BirthControlMethod.none => 'Nothing to track yet.',
      };

  /// Hormonal, non-hormonal, or neither — shown as a caption in the picker.
  String get hormoneTag => switch (this) {
        BirthControlMethod.pill ||
        BirthControlMethod.progestinPill ||
        BirthControlMethod.patch ||
        BirthControlMethod.ring ||
        BirthControlMethod.iud ||
        BirthControlMethod.implant ||
        BirthControlMethod.injection =>
          'Hormonal',
        BirthControlMethod.copperIud ||
        BirthControlMethod.condom ||
        BirthControlMethod.naturalFam =>
          'Non-hormonal',
        BirthControlMethod.other || BirthControlMethod.none => 'Varies',
      };

  /// How often the method needs an action from the user, in a couple of words.
  String get cadence => switch (this) {
        BirthControlMethod.pill ||
        BirthControlMethod.progestinPill =>
          'Every day',
        BirthControlMethod.patch => 'Weekly',
        BirthControlMethod.ring => 'Monthly',
        BirthControlMethod.iud ||
        BirthControlMethod.copperIud ||
        BirthControlMethod.implant =>
          'Every few years',
        BirthControlMethod.injection => 'Every few months',
        BirthControlMethod.condom => 'Each time',
        BirthControlMethod.naturalFam => 'Every day',
        BirthControlMethod.other => 'Varies',
        BirthControlMethod.none => '—',
      };

  /// True for the two methods where a daily check-in and a pack visualiser
  /// actually mean something.
  bool get isDailyPill =>
      this == BirthControlMethod.pill ||
      this == BirthControlMethod.progestinPill;

  /// Whether a 21/7-style pack layout applies. Progestin-only packs are
  /// normally active throughout, so they default to the continuous layout.
  bool get hasPack => isDailyPill;

  static BirthControlMethod fromName(String? name) =>
      BirthControlMethod.values.firstWhere(
        (method) => method.name == name,
        orElse: () => BirthControlMethod.none,
      );

  /// Methods in display order, grouped for the picker sheet.
  static Map<MethodGroup, List<BirthControlMethod>> get grouped {
    final map = <MethodGroup, List<BirthControlMethod>>{};
    for (final method in BirthControlMethod.values) {
      map.putIfAbsent(method.group, () => <BirthControlMethod>[]).add(method);
    }
    return map;
  }
}
