// ─────────────────────────────────────────────────────────────────────────────
// Week-by-week pregnancy content
//
// Pure Dart on purpose. This is a content table, not a widget: keeping it free
// of Flutter imports means it can be unit-tested, reused by a notification
// scheduler, or serialised later without dragging the framework along.
//
// Editorial rules this table follows, and any future edit must keep:
//
//  • Descriptive, never prescriptive. It says what commonly happens, not what
//    the reader should do about it. No dosages, no diagnoses, no treatment.
//  • Anything clinical is routed to the reader's own care team rather than
//    answered here.
//  • Ranges and averages are framed as typical, because pregnancies vary and a
//    reader who differs from the table should not read that as a problem.
//
// Weeks are gestational (counted from the last menstrual period), matching how
// the rest of the feature calculates progress.
// ─────────────────────────────────────────────────────────────────────────────

/// One week's worth of content.
class PregnancyWeek {
  const PregnancyWeek({
    required this.week,
    required this.trimester,
    required this.sizeComparison,
    required this.babyUpdate,
    required this.bodyUpdate,
    required this.tip,
  });

  /// Gestational week, counted from the last menstrual period.
  final int week;

  /// 1, 2 or 3. Matches [PregnancyContent.trimesterFor].
  final int trimester;

  /// Everyday object of roughly comparable size, e.g. `'lime'`.
  ///
  /// Deliberately not a measurement in centimetres: a reader can picture a lime
  /// instantly and cannot picture 5.4cm at all.
  final String sizeComparison;

  final String babyUpdate;
  final String bodyUpdate;

  /// One practical, non-prescriptive line.
  final String tip;
}

/// The week-by-week table, covering weeks 4 through 40.
class PregnancyContent {
  PregnancyContent._();

  /// First week with content. Earlier than this there is little to describe and
  /// most people have not yet missed a period.
  static const int minWeek = 4;

  /// Last week with content. Past-due weeks resolve to this entry.
  static const int maxWeek = 40;

  /// Returns the entry for [week], or the nearest defined one if [week] falls
  /// outside the table. Never returns null, so callers do not need a fallback.
  static PregnancyWeek forWeek(int week) {
    var best = weeks.first;
    var bestDistance = (best.week - week).abs();
    for (final entry in weeks) {
      final distance = (entry.week - week).abs();
      if (distance < bestDistance) {
        best = entry;
        bestDistance = distance;
      }
    }
    return best;
  }

  /// 1 for weeks up to 13, 2 for 14–27, 3 from 28 onward.
  static int trimesterFor(int week) {
    if (week <= 13) return 1;
    if (week <= 27) return 2;
    return 3;
  }

  /// Ordinal label for a trimester number, e.g. `'2nd'`.
  static String trimesterLabel(int trimester) {
    return switch (trimester) {
      1 => '1st',
      2 => '2nd',
      _ => '3rd',
    };
  }

  /// Inclusive week range for a trimester, useful for jump-to controls.
  static ({int start, int end}) trimesterRange(int trimester) {
    return switch (trimester) {
      1 => (start: minWeek, end: 13),
      2 => (start: 14, end: 27),
      _ => (start: 28, end: maxWeek),
    };
  }

  static const List<PregnancyWeek> weeks = [
    PregnancyWeek(
      week: 4,
      trimester: 1,
      sizeComparison: 'poppy seed',
      babyUpdate: 'The ball of cells that will become your baby has settled '
          'into the lining of the uterus and is now called an embryo. The '
          'amniotic sac and the earliest structures of the placenta are '
          'forming around it.',
      bodyUpdate: 'Many people notice nothing beyond a missed period this '
          'week. Others feel mild cramping or light spotting as implantation '
          'happens, along with tender breasts and unusual tiredness.',
      tip: 'Note the first day of your last period somewhere you will not '
          'lose it — it is the first thing a midwife or doctor will ask for.',
    ),
    PregnancyWeek(
      week: 5,
      trimester: 1,
      sizeComparison: 'sesame seed',
      babyUpdate: 'The neural tube, which becomes the brain and spinal cord, '
          'is closing along the length of the embryo. A small cluster of cells '
          'starts to pulse — the earliest version of a heart.',
      bodyUpdate: 'Pregnancy hormones are climbing quickly, and this is often '
          'the week nausea and a strange metallic taste arrive. Sudden '
          'aversions to coffee or to food you normally like are common.',
      tip: 'If mornings are the worst part, some people find eating something '
          'plain before getting out of bed settles their stomach.',
    ),
    PregnancyWeek(
      week: 6,
      trimester: 1,
      sizeComparison: 'lentil',
      babyUpdate: 'Facial features begin as dark spots and shallow pits where '
          'the eyes and ears will be. Arm and leg buds appear as small paddles, '
          "and the heart is beating at roughly twice an adult's rate.",
      bodyUpdate: 'Breast tenderness and needing the bathroom constantly tend '
          'to show up together around now. Fatigue can feel wildly out of '
          'proportion to how much you have actually done.',
      tip: 'Short rests beat pushing through. Early-pregnancy tiredness '
          'responds far better to sleep than to caffeine.',
    ),
    PregnancyWeek(
      week: 7,
      trimester: 1,
      sizeComparison: 'blueberry',
      babyUpdate: 'The brain is growing fast, adding cells at an extraordinary '
          'rate. Hands and feet are still webbed paddles, and the small tail '
          'the embryo started with is beginning to disappear.',
      bodyUpdate: 'Saliva may increase and your sense of smell can turn '
          'uncomfortably sharp. The uterus has already doubled in size, even '
          'though nothing shows from the outside yet.',
      tip: 'Keep a plain snack in your bag. Long gaps between meals tend to '
          'make nausea worse rather than better.',
    ),
    PregnancyWeek(
      week: 8,
      trimester: 1,
      sizeComparison: 'raspberry',
      babyUpdate: 'Fingers and toes are separating from the paddles, and '
          'eyelids have formed but stay fused shut. Breathing tubes are '
          'branching from the throat down toward the developing lungs.',
      bodyUpdate: 'Your waistband may feel snug from bloating rather than from '
          'the bump. Mood shifts are common — hormones are changing faster now '
          'than at almost any other point.',
      tip: 'This is the usual window for booking your first scan and '
          'appointment, if that is not already in the calendar.',
    ),
    PregnancyWeek(
      week: 9,
      trimester: 1,
      sizeComparison: 'green olive',
      babyUpdate: 'The embryo is officially called a fetus from this week. The '
          'essential organs are all present in basic form, and tiny muscles '
          'allow the first jerky movements, far too small to feel.',
      bodyUpdate: 'Nausea often peaks somewhere around now, which is worth '
          'knowing because it usually means the far side is close. Veins may '
          'look more visible as blood volume rises.',
      tip: 'Soft, loose clothing helps more than you would expect while your '
          'shape is changing week to week.',
    ),
    PregnancyWeek(
      week: 10,
      trimester: 1,
      sizeComparison: 'kumquat',
      babyUpdate: 'Tiny nails are starting on the fingers and toes, and the '
          'bones of the arms and legs are beginning to harden. The stomach is '
          'producing digestive juices and the kidneys are making urine.',
      bodyUpdate: 'Twinges along the sides of the abdomen as the uterus '
          'stretches can catch you off guard. Headaches turn up for some '
          'people as blood vessels adapt to the extra volume.',
      tip: 'Stand up slowly. Feeling briefly dizzy on rising is common now '
          'that your circulation is working differently.',
    ),
    PregnancyWeek(
      week: 11,
      trimester: 1,
      sizeComparison: 'fig',
      babyUpdate: 'The head is still around half the total length, but the '
          'body is catching up quickly. Hands can open and close into fists, '
          'and hair follicles are forming across the skin.',
      bodyUpdate: 'The worst of the nausea starts to ease for many people '
          'around this point. Appetite can return suddenly and with real '
          'force after weeks of nothing appealing.',
      tip: 'Gentle regular movement, like a walk most days, tends to do more '
          'for energy and sleep right now than intense sessions.',
    ),
    PregnancyWeek(
      week: 12,
      trimester: 1,
      sizeComparison: 'lime',
      babyUpdate: 'Reflexes are developing: fingers curl, toes flex, and the '
          'fetus can suck. The face has moved into recognisable proportions '
          'with the eyes settled at the front rather than the sides.',
      bodyUpdate: 'The uterus has grown beyond the pelvis and you may be able '
          'to feel it low in your abdomen. Skin changes in either direction, a '
          'glow or a breakout, are both normal.',
      tip: 'The end of the first trimester is a natural moment to think about '
          'who you want to tell, and when.',
    ),
    PregnancyWeek(
      week: 13,
      trimester: 1,
      sizeComparison: 'pea pod',
      babyUpdate: 'Vocal cords are forming, and the intestines have moved from '
          'the umbilical cord into the abdomen where they belong. Fingerprints '
          'have already appeared on the fingertips.',
      bodyUpdate: 'Energy often returns this week and the constant sleepiness '
          'lifts. Some people notice a darker vertical line appearing down the '
          'middle of the belly.',
      tip: 'If food has been unappealing for weeks, the returning appetite is '
          'a good chance to eat across a broader range again.',
    ),
    PregnancyWeek(
      week: 14,
      trimester: 2,
      sizeComparison: 'lemon',
      babyUpdate: 'The fetus can make facial expressions, squinting and '
          'frowning, though not deliberately. A fine downy hair called lanugo '
          'is spreading across the skin.',
      bodyUpdate: 'The second trimester begins. Breasts keep growing while '
          'nausea recedes, and many people describe finally feeling like '
          'themselves again.',
      tip: 'A supportive bra fitted to your current size, not your old one, '
          'makes a genuine difference to how the day feels.',
    ),
    PregnancyWeek(
      week: 15,
      trimester: 2,
      sizeComparison: 'apple',
      babyUpdate: 'Bones are becoming denser and now show up clearly on a '
          'scan. The fetus is moving amniotic fluid in and out through its '
          'nose and airways, rehearsing for breathing.',
      bodyUpdate: 'You may be visibly showing. Blocked nose and the occasional '
          'nosebleed happen as blood flow to the mucous membranes increases.',
      tip: 'Sleeping slightly propped up eases pregnancy congestion for a lot '
          'of people without needing anything from a pharmacy.',
    ),
    PregnancyWeek(
      week: 16,
      trimester: 2,
      sizeComparison: 'avocado',
      babyUpdate: 'The eyes are starting to move behind closed lids and can '
          'register light through the abdominal wall. Leg muscles are strong '
          'enough now for definite kicks.',
      bodyUpdate: 'Some people feel the first flutters of movement, called '
          'quickening, particularly if this is not a first pregnancy. Your '
          'heart is pumping noticeably more blood than it was.',
      tip: 'Note roughly when you first feel movement. Your care team will '
          'ask, and it is surprisingly easy to forget.',
    ),
    PregnancyWeek(
      week: 17,
      trimester: 2,
      sizeComparison: 'turnip',
      babyUpdate: 'Fat stores are starting to build beneath skin that is still '
          'thin and translucent. Soft cartilage throughout the skeleton is '
          'hardening into bone.',
      bodyUpdate: 'Your centre of gravity is shifting and backache can begin. '
          'Vivid, strange dreams are very widely reported around this stage.',
      tip: 'Sitting with both feet flat and your lower back supported protects '
          'your back better than any single stretch does.',
    ),
    PregnancyWeek(
      week: 18,
      trimester: 2,
      sizeComparison: 'bell pepper',
      babyUpdate: 'The ears have moved into their final position and the fetus '
          'may react to loud sounds. Nerves are gaining a protective coating '
          'that speeds up the signals travelling along them.',
      bodyUpdate: 'You may feel stretching along the sides of the abdomen. '
          'Occasional lightheadedness is common while blood pressure runs a '
          'little lower than usual.',
      tip: 'The mid-pregnancy anatomy scan usually falls within the next '
          'couple of weeks, so it is worth checking it is booked.',
    ),
    PregnancyWeek(
      week: 19,
      trimester: 2,
      sizeComparison: 'mango',
      babyUpdate: 'A waxy white coating called vernix forms over the skin to '
          'protect it from months in amniotic fluid. The brain is mapping out '
          'dedicated areas for touch, taste, smell, sight and hearing.',
      bodyUpdate: 'Hips and pelvis can ache as the ligaments loosen. Skin '
          'across the belly may feel tight, dry and itchy as it stretches.',
      tip: 'Unscented moisturiser will not prevent stretch marks, but it does '
          'help with the itch while the skin stretches.',
    ),
    PregnancyWeek(
      week: 20,
      trimester: 2,
      sizeComparison: 'banana',
      babyUpdate: 'Roughly the halfway mark. The fetus is swallowing more and '
          'its digestive system is producing meconium. Distinct sleeping and '
          'waking cycles are starting to appear.',
      bodyUpdate: 'Your uterus is around the level of your navel. Movements '
          'should be getting clearer and falling into something more like a '
          'pattern.',
      tip: "Start noticing your baby's usual pattern of activity — knowing "
          'what is normal for them is genuinely useful later on.',
    ),
    PregnancyWeek(
      week: 21,
      trimester: 2,
      sizeComparison: 'carrot',
      babyUpdate: 'Eyebrows and eyelids are fully formed. The fetus responds '
          'to sound and may startle at something sudden and loud.',
      bodyUpdate: 'Braxton Hicks tightenings can begin — usually painless, '
          'irregular, and easing off on their own. Feet may swell by the end '
          'of a long day.',
      tip: 'Putting your feet up above hip level for a while in the evening '
          'helps end-of-day swelling settle.',
    ),
    PregnancyWeek(
      week: 22,
      trimester: 2,
      sizeComparison: 'spaghetti squash',
      babyUpdate: 'Lips, eyelids and eyebrows are distinct, and the first '
          'tooth buds are sitting under the gums. Grip is developing, and the '
          'fetus may hold onto the umbilical cord.',
      bodyUpdate: 'Hair may look thicker as normal shedding slows down. '
          'Heartburn becomes more common as the uterus presses upward on the '
          'stomach.',
      tip: 'Smaller meals more often, and staying upright for a while after '
          'eating, is what tends to help reflux most.',
    ),
    PregnancyWeek(
      week: 23,
      trimester: 2,
      sizeComparison: 'large grapefruit',
      babyUpdate: 'The lungs are building the network of blood vessels they '
          'will need to breathe air. Hearing is now good enough to pick your '
          'voice out from background noise.',
      bodyUpdate: 'Balance can feel slightly off as your shape changes. Some '
          'people notice their belly button flattening or protruding.',
      tip: 'Talking or reading aloud is not purely sentimental — your baby is '
          'learning the sound of your voice.',
    ),
    PregnancyWeek(
      week: 24,
      trimester: 2,
      sizeComparison: 'ear of corn',
      babyUpdate: 'The lungs start producing surfactant, the substance that '
          'lets air sacs stay open. Facial features are essentially complete '
          'and now just need fat to fill them out.',
      bodyUpdate: 'Stretch marks may appear across the belly, breasts, hips or '
          'thighs. Leg cramps that wake you at night are common at this stage.',
      tip: 'Standing calf stretches before bed help some people avoid the '
          'middle-of-the-night cramp entirely.',
    ),
    PregnancyWeek(
      week: 25,
      trimester: 2,
      sizeComparison: 'rutabaga',
      babyUpdate: 'Fat is filling out skin that was wrinkled, and hair is '
          'developing real colour and texture. Reactions to your movement and '
          'to sound are becoming clearer and more consistent.',
      bodyUpdate: 'Sleep gets harder as finding a comfortable position turns '
          'into a project. Constipation and haemorrhoids are unglamorous but '
          'extremely common.',
      tip: 'Fibre and fluids together do far more for pregnancy constipation '
          'than either one does alone.',
    ),
    PregnancyWeek(
      week: 26,
      trimester: 2,
      sizeComparison: 'scallion',
      babyUpdate: 'The eyes are beginning to open after months fused shut. '
          'Brainwave activity for hearing and for sight is now detectable.',
      bodyUpdate: 'Your bump is probably making stairs and shoelaces real '
          'work. Discomfort under the ribs can start as the uterus pushes '
          'upward.',
      tip: 'A pillow between your knees when sleeping on your side takes real '
          'strain off your hips and lower back.',
    ),
    PregnancyWeek(
      week: 27,
      trimester: 2,
      sizeComparison: 'cauliflower',
      babyUpdate: 'Sleeping and waking rhythms are established, and hiccups '
          'may be noticeable as light rhythmic taps. The lungs are still '
          'immature but developing steadily week by week.',
      bodyUpdate: 'Last week of the second trimester. Getting out of breath '
          'from mild effort is normal now that your diaphragm has less room to '
          'work with.',
      tip: 'A good week to ask about your options for birth and start '
          'thinking about what you would prefer.',
    ),
    PregnancyWeek(
      week: 28,
      trimester: 3,
      sizeComparison: 'large eggplant',
      babyUpdate: 'The eyes can open and blink, and the fetus can tell light '
          'from dark through the abdominal wall. Fat keeps building while the '
          'brain develops its deep characteristic folds.',
      bodyUpdate: 'The third trimester begins and appointments usually get '
          'more frequent from here. Braxton Hicks tightenings may be more '
          'noticeable than they were.',
      tip: 'Counting movements at a similar time each day, when your baby is '
          'usually active, makes any change easier to notice.',
    ),
    PregnancyWeek(
      week: 29,
      trimester: 3,
      sizeComparison: 'butternut squash',
      babyUpdate: 'Bones are taking up a lot of calcium as the skeleton '
          'hardens. Kicks and jabs feel stronger and more purposeful now that '
          'there is less room to move around in.',
      bodyUpdate: 'Heartburn, breathlessness and frequent bathroom trips can '
          'all overlap now. Varicose veins may become more visible in the legs.',
      tip: 'Anything you can do sitting rather than standing is worth doing '
          'sitting this trimester.',
    ),
    PregnancyWeek(
      week: 30,
      trimester: 3,
      sizeComparison: 'large cabbage',
      babyUpdate: 'Lanugo starts to disappear as the fetus becomes better at '
          'holding its own temperature. Bone marrow has taken over production '
          'of red blood cells.',
      bodyUpdate: 'Amniotic fluid begins to decrease from around now as the '
          'baby takes up more of the available room. Deep fatigue often '
          'returns after a comfortable stretch.',
      tip: 'Naps count. Third-trimester tiredness is not a sign you are doing '
          'anything wrong.',
    ),
    PregnancyWeek(
      week: 31,
      trimester: 3,
      sizeComparison: 'coconut',
      babyUpdate: 'All five senses are working. The fetus can turn its head, '
          'and rapid brain and nerve development carries on right through to '
          'birth and beyond.',
      bodyUpdate: 'Breasts may start leaking colostrum. Braxton Hicks '
          'contractions can arrive in stronger patches that settle again.',
      tip: 'Learning the difference between practice tightenings and '
          'rhythmic, regular contractions is worth doing before you need it.',
    ),
    PregnancyWeek(
      week: 32,
      trimester: 3,
      sizeComparison: 'jicama',
      babyUpdate: 'Fingernails and toenails have fully grown in and the hair '
          'on the head may be thick. Most babies have settled head-down by '
          'now, though plenty still have not.',
      bodyUpdate: 'The bump feels heavy and low. Sleep is often broken by a '
          'mix of discomfort and trips to the bathroom.',
      tip: "Ask about your baby's position at your next appointment — it is "
          'one of the things being checked at each visit.',
    ),
    PregnancyWeek(
      week: 33,
      trimester: 3,
      sizeComparison: 'pineapple',
      babyUpdate: 'The skull bones stay unfused and flexible so the head can '
          'move through the birth canal. The immune system is picking up '
          'antibodies passed across from you.',
      bodyUpdate: 'Pelvic pressure increases and walking may turn into a '
          'waddle. Numbness or tingling in the hands can happen from fluid '
          'retention.',
      tip: 'If you are planning to work up to your due date, it is worth '
          'sketching out a backup plan as well.',
    ),
    PregnancyWeek(
      week: 34,
      trimester: 3,
      sizeComparison: 'cantaloupe',
      babyUpdate: 'The lungs are close to mature and the central nervous '
          'system is well developed. Vernix is thickening and most of what '
          'happens from here is weight gain.',
      bodyUpdate: 'Vision may feel slightly blurrier and eyes drier than '
          'usual. Fatigue and hip discomfort are typical company at this '
          'stage.',
      tip: 'Get your bag roughly packed now, while it is a calm decision '
          'rather than a rushed one.',
    ),
    PregnancyWeek(
      week: 35,
      trimester: 3,
      sizeComparison: 'honeydew melon',
      babyUpdate: 'Most development is complete and the remaining weeks are '
          'largely about growth. The kidneys are fully developed and the liver '
          'is processing some waste on its own.',
      bodyUpdate: 'Your uterus is pressing up against your ribs and lungs. '
          'Frequent urination is at roughly its most inconvenient.',
      tip: 'Know your route to where you plan to give birth, including at a '
          'time of day when the traffic is bad.',
    ),
    PregnancyWeek(
      week: 36,
      trimester: 3,
      sizeComparison: 'head of romaine',
      babyUpdate: 'The baby may drop lower into the pelvis, a shift often '
          'called lightening. Cheek muscles and the sucking reflex are ready '
          'for feeding.',
      bodyUpdate: 'Breathing may get easier once the baby drops, while pelvic '
          'pressure increases in exchange. Weekly appointments are common from '
          'here on.',
      tip: 'If breathing suddenly feels easier and you need the bathroom even '
          'more, the baby has likely moved down.',
    ),
    PregnancyWeek(
      week: 37,
      trimester: 3,
      sizeComparison: 'bunch of Swiss chard',
      babyUpdate: 'Considered early term. The baby practises breathing, '
          'sucking and blinking while continuing to gain weight. The gut is '
          'getting ready for a first feed.',
      bodyUpdate: 'You may notice thicker discharge, or lose the mucus plug. '
          'A burst of nesting energy or complete exhaustion can both show up, '
          'sometimes on the same day.',
      tip: 'Write down the signs your care team asked you to call about, and '
          'put the list somewhere you will actually see it.',
    ),
    PregnancyWeek(
      week: 38,
      trimester: 3,
      sizeComparison: 'rhubarb stalk',
      babyUpdate: 'The lungs are still finishing their final stage of '
          'maturing. Fat has filled out the arms, legs and cheeks, and hair '
          'colour may not be what anyone predicted.',
      bodyUpdate: 'Feet and ankles may swell more than before. Practice '
          'contractions can be strong enough to make you genuinely wonder if '
          'this is it.',
      tip: 'Timing from the start of one contraction to the start of the next '
          'is the number your care team will ask for.',
    ),
    PregnancyWeek(
      week: 39,
      trimester: 3,
      sizeComparison: 'mini watermelon',
      babyUpdate: 'Full term. The baby is adding the last layers of fat needed '
          'to hold its temperature after birth, and the cord is still passing '
          'antibodies across right up to delivery.',
      bodyUpdate: 'The cervix begins to soften and thin. Sleep is broken and '
          'patience is generally thin too, which is entirely fair.',
      tip: 'Rest without waiting to feel tired. Labour is unpredictable and '
          'stored rest is useful.',
    ),
    PregnancyWeek(
      week: 40,
      trimester: 3,
      sizeComparison: 'small pumpkin',
      babyUpdate: 'The baby is ready to be born, though only a small minority '
          'arrive exactly on the due date. Nails may extend past the '
          'fingertips and the skull stays flexible for the journey.',
      bodyUpdate: 'Contractions may become regular and steadily more intense. '
          'A rush of energy, a rush of nerves, or both at once are all normal '
          'in this stretch.',
      tip: 'A due date is a midpoint estimate rather than a deadline — your '
          'care team will talk you through what happens if you go past it.',
    ),
  ];
}
