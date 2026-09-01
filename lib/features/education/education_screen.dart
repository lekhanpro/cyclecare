import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import 'application/education_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The library
//
// Twenty articles is past the point where a flat scrolling list works. Once a
// user has read a few, the only thing they want is the one they half remember,
// so search is the primary control here and the category chips are the
// secondary one. Bookmarks and read-state live in SharedPreferences via
// `education_controller.dart` — a saved article that disappears on tab switch
// is worse than no bookmark button at all.
//
// Content rules for everything below: describe mechanisms, name the symptoms
// worth escalating, and stop there. No dosages, no diagnoses, no "you have".
// ─────────────────────────────────────────────────────────────────────────────

// ─── Model ───────────────────────────────────────────────────────────────────

enum ArticleCategory {
  basics('Cycle basics', '🌸'),
  fertility('Fertility', '🌿'),
  symptoms('Symptoms', '🌙'),
  nutrition('Nutrition', '🥗'),
  conditions('Conditions', '🩺'),
  wellbeing('Wellbeing', '🧘');

  const ArticleCategory(this.label, this.emoji);

  final String label;
  final String emoji;

  /// A distinct hue per category so the list is scannable without reading.
  ///
  /// Deliberately not the palette accent: twenty cards in one colour give the
  /// eye nothing to sort by. The semantic cycle hues are reused because they
  /// are already learned elsewhere in the app.
  Color get seed => switch (this) {
        ArticleCategory.basics => AppColors.period,
        ArticleCategory.fertility => AppColors.fertile,
        ArticleCategory.symptoms => AppColors.ovulation,
        ArticleCategory.nutrition => AppColors.success,
        ArticleCategory.conditions => AppColors.info,
        ArticleCategory.wellbeing => AppColors.luteal,
      };

  /// [seed], lifted for legibility on a near-black surface. The raw hues are
  /// tuned for cream and go muddy in dark mode.
  Color tone(BuildContext context) {
    if (!context.isDark) return seed;
    final hsl = HSLColor.fromColor(seed);
    return hsl.withLightness((hsl.lightness + 0.14).clamp(0.0, 1.0)).toColor();
  }
}

@immutable
class Article {
  const Article({
    required this.id,
    required this.title,
    required this.category,
    required this.emoji,
    required this.readMinutes,
    required this.summary,
    required this.body,
  });

  final String id;
  final String title;
  final ArticleCategory category;
  final String emoji;

  /// Rounded reading-time estimate. Set by hand rather than computed from word
  /// count — some of these are dense and read slower than their length says.
  final int readMinutes;

  final String summary;

  /// Light markup: `## ` for a section heading, `- ` for a bullet,
  /// `**text**` for inline emphasis. Blank lines separate paragraphs.
  final String body;

  /// Everything search looks at, lowercased once at construction time would be
  /// nicer, but these are `const` — so it is built per query instead, which at
  /// twenty articles costs nothing measurable.
  bool matches(String lowercaseQuery) {
    if (lowercaseQuery.isEmpty) return true;
    return title.toLowerCase().contains(lowercaseQuery) ||
        summary.toLowerCase().contains(lowercaseQuery) ||
        category.label.toLowerCase().contains(lowercaseQuery) ||
        body.toLowerCase().contains(lowercaseQuery);
  }
}

// ─── Content ─────────────────────────────────────────────────────────────────

const kArticles = <Article>[
  // ── Cycle basics ──────────────────────────────────────────────────────────
  Article(
    id: 'cycle-phases',
    title: 'The Four Phases of Your Cycle',
    category: ArticleCategory.basics,
    emoji: '🌸',
    readMinutes: 6,
    summary: 'What actually happens across a month, stage by stage.',
    body: '''
Your cycle is one continuous hormonal loop, but it is easier to read in four stages. Day 1 is the first day of real bleeding, not spotting.

## Menstrual phase, days 1 to 5
The uterine lining sheds because progesterone and oestrogen have both dropped. Energy often sits at its lowest here, and that is a hormonal reality rather than a lack of discipline.

## Follicular phase, days 1 to 13
This overlaps with your period. **Follicle-stimulating hormone** nudges a batch of follicles to grow, and the one that pulls ahead produces rising oestrogen. That oestrogen rebuilds the lining and, for many people, lifts mood, focus and physical capacity.

## Ovulation, around day 14
Oestrogen peaks and triggers a surge of **luteinising hormone**. Roughly 24 to 36 hours later the follicle releases an egg. The egg itself survives 12 to 24 hours.

## Luteal phase, days 15 to 28
The emptied follicle becomes the corpus luteum and produces **progesterone**, which stabilises the lining and raises resting temperature slightly. If no pregnancy occurs, the corpus luteum breaks down, hormones fall, and the next period starts.

## Why the numbers move
The luteal phase is the steady part, usually 11 to 15 days. Most of the variation between cycles comes from the follicular phase, which is why a stressful or unwell month can delay a period without anything being wrong.

Log a few cycles and CycleCare fits these estimates to your own pattern rather than a textbook 28 days.
''',
  ),
  Article(
    id: 'cycle-length',
    title: 'What Counts as a Normal Cycle',
    category: ArticleCategory.basics,
    emoji: '📆',
    readMinutes: 4,
    summary: 'The normal range is wider than most people are told.',
    body: '''
A cycle is measured from the first day of one period to the day before the next. Anything from **21 to 35 days** is considered typical for adults, and 21 to 45 days in the first few years after periods begin.

## Variation is normal
Cycles that swing by a few days month to month are common. Clinically, the pattern matters far more than any single cycle.

## Worth raising with a clinician
- Cycles consistently shorter than 21 days or longer than 35
- A swing of more than 7 to 9 days between your shortest and longest cycle
- Bleeding that lasts longer than 8 days
- Periods that stop for 3 months or more without pregnancy
- Bleeding between periods

## Things that shift a cycle
Illness, travel across time zones, sharp changes in training load, undereating, poor sleep and sustained stress all act on the same hormonal axis. Perimenopause reshapes cycle length too, usually beginning in the forties.

This is general education, not a diagnosis. Bring your logged history to an appointment — a real record is far more useful than recall.
''',
  ),
  Article(
    id: 'reading-flow',
    title: 'Reading Your Flow',
    category: ArticleCategory.basics,
    emoji: '🩸',
    readMinutes: 4,
    summary: 'Colour, volume and clots — what is ordinary and what is not.',
    body: '''
Total blood loss across a typical period is roughly **30 to 80 ml**, which is far less than it looks like. Most of what you see is a mix of blood, lining tissue and cervical fluid.

## Colour
- **Bright red** usually means fresh, faster flow, common on heavy days
- **Dark red or brown** is older blood that took longer to leave, typical at the start and end
- **Pink** can appear when light flow mixes with cervical fluid
- **Orange or grey** discharge with an unusual smell is worth a clinical check

## Volume
Heavy flow, clinically called menorrhagia, means soaking through a pad or tampon every hour or two, needing double protection, or waking at night to change. That is a recognised reason to seek care, not something to push through.

## Clots
Small clots on the heaviest days are ordinary. Clots larger than a coin, cycle after cycle, are worth mentioning.

## What to log
Flow level, product changes and pain give a clinician a picture that memory cannot. Track consistently for two or three cycles before drawing conclusions.

Educational only — no article can assess your bleeding for you.
''',
  ),
  Article(
    id: 'hormones-101',
    title: 'The Hormones Running the Show',
    category: ArticleCategory.basics,
    emoji: '🔬',
    readMinutes: 5,
    summary: 'Four messengers, and what each one is doing.',
    body: '''
Four hormones do most of the work, in a feedback loop between the brain and the ovaries.

## FSH, follicle-stimulating hormone
Released by the pituitary early in the cycle. It recruits follicles and starts the race toward ovulation.

## Oestrogen
Produced by the growing follicle. It thickens the uterine lining, thins cervical mucus so sperm can travel, and supports mood, skin and bone. It climbs through the follicular phase and peaks just before ovulation.

## LH, luteinising hormone
Also from the pituitary. A sharp surge in LH is the trigger that releases the egg. Ovulation predictor strips are looking for exactly this.

## Progesterone
Made by the corpus luteum after ovulation. It quiets uterine contractions, holds the lining in place, raises basal temperature slightly and has a calming, sometimes sedating effect. Its **withdrawal** at the end of the luteal phase is what starts a period.

## Why this matters for tracking
Symptoms cluster where hormones move fastest: the days before a period, and the day or two around ovulation. If your logs show a pattern locked to one of those windows, that is a signal rather than a coincidence.
''',
  ),

  // ── Fertility ─────────────────────────────────────────────────────────────
  Article(
    id: 'fertile-window',
    title: 'The Fertile Window',
    category: ArticleCategory.fertility,
    emoji: '🌿',
    readMinutes: 4,
    summary: 'When conception is actually possible.',
    body: '''
Sperm can survive up to five days in fertile cervical mucus. An egg lives 12 to 24 hours. Together that gives a window of roughly **six days**.

## The window
- The five days before ovulation
- The day of ovulation
- The hours immediately after

Chances are highest in the two or three days ending on ovulation day.

## Signs it is approaching
- Cervical mucus turns clear, stretchy and slippery
- A positive LH test
- Mild one-sided pelvic ache, called mittelschmerz
- A small rise in libido
- A sustained rise in basal body temperature, which confirms ovulation after the fact

## An important limitation
Calendar predictions are estimates built on your history. They are useful for planning and **unreliable as contraception on their own**. Fertility awareness methods only reach their published effectiveness with formal instruction and daily observation of more than one sign.

CycleCare sharpens its estimate with every cycle you log.
''',
  ),
  Article(
    id: 'bbt',
    title: 'Basal Body Temperature',
    category: ArticleCategory.fertility,
    emoji: '🌡️',
    readMinutes: 5,
    summary: 'A quiet daily number that confirms ovulation happened.',
    body: '''
Basal body temperature is your lowest resting temperature, taken before you sit up, speak or drink anything.

## What you are looking for
After ovulation, progesterone raises BBT by about **0.2 to 0.5 °C**, roughly 0.4 to 1 °F. The rise holds until the next period. Seeing that shift, then a sustained plateau, is good evidence ovulation occurred.

## How to take it well
- Use a basal thermometer that reads to two decimal places
- Same time every morning, after at least three hours of unbroken sleep
- Before getting out of bed
- Record it immediately, then read the trend rather than any single day

## What throws it off
Alcohol the night before, a fever, a late night, a heated blanket, or measuring an hour later than usual. Note those days so you can discount them instead of chasing a phantom shift.

## The honest limitation
BBT is retrospective. It confirms ovulation after it happens, so on its own it cannot tell you your fertile days are starting. Pair it with cervical mucus for a forward-looking signal.
''',
  ),
  Article(
    id: 'cervical-mucus',
    title: 'Cervical Mucus as a Signal',
    category: ArticleCategory.fertility,
    emoji: '💧',
    readMinutes: 4,
    summary: 'The most useful real-time fertility sign you already have.',
    body: '''
Cervical mucus changes across the cycle under oestrogen, and unlike temperature it changes **before** ovulation rather than after.

## The progression
- Just after your period: little or nothing, dry
- Early follicular: sticky, tacky, pasty, white
- Mid follicular: creamy, lotion-like
- Peak: clear, stretchy, slippery, similar to raw egg white
- After ovulation: abruptly drier or thicker as progesterone rises

The last day of clear slippery mucus is called the peak day, and ovulation usually falls within a day either side of it.

## Observing without overthinking
Check at the same points each day, for example after using the bathroom, and note the most fertile quality you saw. Two or three cycles of notes will show you your own pattern, which matters more than any chart.

## When to ask about it
Persistent itching, unusual colour, a strong odour, or pain alongside changed discharge points toward infection rather than a cycle change, and deserves a clinical opinion.
''',
  ),
  Article(
    id: 'lh-tests',
    title: 'Ovulation Tests and the LH Surge',
    category: ArticleCategory.fertility,
    emoji: '🧪',
    readMinutes: 4,
    summary: 'How strips work, and the four ways they mislead.',
    body: '''
Ovulation predictor kits detect luteinising hormone in urine. LH climbs sharply **24 to 36 hours before** the egg is released, so a positive test points at the most fertile days ahead.

## Getting a usable result
- Start testing a few days before your earliest expected ovulation, based on your shortest recent cycle
- Test at a consistent time; late morning to early afternoon suits many people
- Avoid drinking a large volume of water immediately before, which dilutes the sample
- Once positive, the surge is underway and further testing adds little

## Where strips mislead
- A positive shows a surge, not that an egg was actually released
- Some people surge more than once in a cycle
- A higher baseline LH, seen in some cases of PCOS, can produce repeated positives
- Hormonal contraception and some fertility medications interfere with results

Strips are a planning tool. Persistent difficulty conceiving, or results that never turn positive across several cycles, deserves a conversation with a clinician rather than more tests.
''',
  ),

  // ── Symptoms ──────────────────────────────────────────────────────────────
  Article(
    id: 'cramps',
    title: 'Why Cramps Happen',
    category: ArticleCategory.symptoms,
    emoji: '🌙',
    readMinutes: 5,
    summary: 'The mechanism behind period pain, and what tends to help.',
    body: '''
Before a period, the uterine lining releases **prostaglandins**. These make the uterus contract to shed the lining, and they also constrict local blood vessels. Strong contractions plus briefly reduced blood flow is what you feel as cramping.

## Primary and secondary
Primary dysmenorrhoea is pain from the process itself, with no underlying disease. It usually starts within a day of bleeding and eases over two or three days.

Secondary dysmenorrhoea is pain caused by something else — endometriosis, fibroids, adenomyosis, an infection. Clues include pain that began years after your periods did, pain outside your period, pain during sex, or pain that keeps getting worse.

## Approaches people find useful
- Continuous local heat, which relaxes the muscle
- Regular aerobic movement across the month, not only on painful days
- Protected sleep, since pain sensitivity climbs when sleep is short
- Over-the-counter anti-inflammatory medicines, which act directly on prostaglandins — a pharmacist or clinician can advise whether they suit you

## Do not normalise severe pain
Pain that keeps you from school, work or sleep is not something to earn your way through. Roughly one in ten people with periods has endometriosis, and average time to diagnosis is still measured in years. Logged pain scores make that conversation concrete.

Educational only, and deliberately without specific medicines or doses.
''',
  ),
  Article(
    id: 'pms-pmdd',
    title: 'PMS and PMDD',
    category: ArticleCategory.symptoms,
    emoji: '💜',
    readMinutes: 5,
    summary: 'Where premenstrual symptoms cross into a disorder.',
    body: '''
Both sit in the luteal phase and both ease within a few days of bleeding starting. The difference is severity and impact.

## PMS
Very common. Bloating, breast tenderness, fatigue, food cravings, irritability, low mood, disturbed sleep. Uncomfortable, sometimes miserable, but the week still functions.

## PMDD
Affects a small minority, commonly cited at around **3 to 8 percent**. The mood symptoms dominate — marked depression, anxiety, anger, a sense of being overwhelmed or out of control — and they interfere with relationships, work or study. PMDD appears in diagnostic manuals as a depressive disorder, and it is treatable.

## The key is timing, not severity alone
Symptoms confined to the luteal phase, absent in the follicular phase, across at least two consecutive cycles. That is exactly what prospective daily logging shows and recall does not, which is why clinicians ask for a symptom diary.

## Support that is commonly discussed
- Consistent aerobic exercise
- Protected sleep in the luteal week
- Reducing alcohol, which worsens both mood and sleep
- Cognitive behavioural approaches
- Several medical options, which a clinician can walk through

If premenstrual weeks bring thoughts of self-harm, treat that as urgent and contact a health professional or a local crisis line rather than waiting for the next cycle.
''',
  ),
  Article(
    id: 'cycle-headaches',
    title: 'Cycle Headaches and Migraine',
    category: ArticleCategory.symptoms,
    emoji: '🤕',
    readMinutes: 4,
    summary: 'Why some headaches track your hormones.',
    body: '''
For many people headaches cluster in a narrow window: the two days before a period and the first three days of it. The trigger appears to be the **drop** in oestrogen rather than any particular level.

## Menstrual migraine
Attacks tied to that oestrogen withdrawal are often longer, more likely to recur, and less responsive to usual treatment than attacks at other times. They are usually without aura.

## Patterns worth capturing
- Which cycle day the headache starts
- Duration and intensity
- Aura, nausea or light sensitivity
- Sleep the night before, and caffeine intake
- What you tried, and whether it helped

Two or three cycles of this is often enough to show a clinician a hormonal pattern rather than a vague complaint.

## Stability helps
Regular sleep and meal timing, steady hydration, and consistent caffeine rather than swings all reduce overall attack likelihood.

## Seek care promptly for
A sudden severe headache unlike any before, headache with fever or a stiff neck, new neurological symptoms, or aura appearing for the first time while using combined hormonal contraception.
''',
  ),

  // ── Nutrition ─────────────────────────────────────────────────────────────
  Article(
    id: 'eating-with-cycle',
    title: 'Eating Across Your Cycle',
    category: ArticleCategory.nutrition,
    emoji: '🥗',
    readMinutes: 5,
    summary: 'Small shifts that match what your body is doing.',
    body: '''
Nothing here is a diet. Total intake and overall quality matter far more than phase-specific tweaks. That said, needs do shift.

## Menstrual phase
Iron losses are real, so iron-rich foods earn their place: lentils, beans, tofu, dark leafy greens, red meat if you eat it. Vitamin C in the same meal improves absorption of plant iron. Magnesium-rich foods such as nuts, seeds and dark chocolate are often mentioned for cramps.

## Follicular phase
Rising oestrogen and generally better energy suit ordinary, protein-adequate meals. Fibre and fermented foods support the gut bacteria involved in clearing oestrogen.

## Around ovulation
Colourful plants, olive oil, oily fish, nuts. Zinc and dietary antioxidants are involved in reproductive function.

## Luteal phase
Resting metabolic rate rises modestly and appetite often follows — that is physiology, not weakness. Complex carbohydrates with protein help steady mood and blood sugar. Cutting back on very salty food reduces the fluid retention behind premenstrual bloating.

## Two honest caveats
Evidence for phase-based eating is thinner than the internet suggests, and individual needs vary a great deal. Anyone with anaemia, a restrictive eating history or a diagnosed condition should work with a clinician or registered dietitian rather than a general article.
''',
  ),
  Article(
    id: 'iron-energy',
    title: 'Iron, Blood Loss and Energy',
    category: ArticleCategory.nutrition,
    emoji: '🥬',
    readMinutes: 4,
    summary: 'Why heavy periods and exhaustion travel together.',
    body: '''
Every period costs iron. With heavy or long bleeding, monthly losses can outpace what your diet replaces, and stores drain quietly over months.

## What low iron feels like
Fatigue that rest does not fix, breathlessness on stairs, dizziness, cold hands, poor concentration, hair shedding, brittle nails, restless legs, sometimes a craving for ice. Symptoms appear well before a blood count looks abnormal, because **ferritin**, the stored form, falls first.

## Two forms in food
- **Haem iron**, from meat, poultry and fish, is absorbed readily
- **Non-haem iron**, from legumes, tofu, seeds, wholegrains and dark greens, is absorbed less well but improves markedly alongside vitamin C

Tea, coffee and calcium taken with a meal reduce absorption, so timing them away from your main iron-containing meals helps.

## Test before supplementing
Iron supplements are not harmless. Excess iron accumulates and causes damage, and fatigue has many other causes. A ferritin level and full blood count is the right starting point, and dosing is a clinical decision rather than a guess.

## Bring your log
Recorded flow levels and product changes let a clinician judge whether bleeding volume explains the tiredness.
''',
  ),
  Article(
    id: 'bloating-fluid',
    title: 'Bloating and Fluid Balance',
    category: ArticleCategory.nutrition,
    emoji: '🎈',
    readMinutes: 4,
    summary: 'Why the luteal week feels tighter, and what helps.',
    body: '''
Premenstrual bloating has two separate causes that are easy to confuse.

## Fluid retention
Shifting oestrogen and progesterone influence the hormonal system that controls sodium and water handling. The result is genuine water retention, often a kilogram or two, showing up in fingers, ankles, breasts and abdomen. It resolves in the first days of bleeding.

## Gut slowing
Progesterone relaxes smooth muscle, including the gut wall. Transit slows, gas accumulates, and constipation is common in the luteal phase. Prostaglandins at the start of a period can then swing things the other way.

## What tends to help
- Steady water intake — drinking less makes retention worse, not better
- Less very salty and heavily processed food in the luteal week
- Potassium-rich foods such as bananas, potatoes and beans
- Gentle movement, especially walking after meals
- Adequate fibre, increased gradually rather than all at once

## When it is not cycle bloating
Bloating that does not resolve after your period, or comes with weight loss, blood in stool, vomiting or persistent abdominal pain, needs assessment. Lasting bloating is also one of the vaguer symptoms of ovarian conditions, which is a reason to get persistent changes checked rather than a reason to panic.
''',
  ),

  // ── Conditions ────────────────────────────────────────────────────────────
  Article(
    id: 'pcos',
    title: 'PCOS: The Basics',
    category: ArticleCategory.conditions,
    emoji: '🩺',
    readMinutes: 6,
    summary: 'A common hormonal condition, often misunderstood.',
    body: '''
Polycystic ovary syndrome is among the most common endocrine conditions in people of reproductive age, affecting roughly **8 to 13 percent**, and a large share go undiagnosed.

## How it is identified
Widely used criteria require two of three features:
- Irregular or absent ovulation, which usually shows as long or unpredictable cycles
- Clinical or biochemical signs of raised androgens, such as persistent acne or unwanted hair growth
- Ovaries with many small follicles on ultrasound

The name is misleading. Those follicles are not cysts in the usual sense, and PCOS can be present without them.

## Why cycles go long
Follicles start to develop but often none reaches the point of ovulation, so no corpus luteum forms and no progesterone withdrawal triggers a period on schedule. Cycles stretch, sometimes to months.

## Associated concerns
Insulin resistance is common, independent of body weight, and raises longer-term risk of type 2 diabetes. There are also links to lipid changes, mood disorders and sleep apnoea. Fertility is often reduced but frequently treatable.

## What helps, broadly
Regular physical activity and a nutritionally adequate pattern of eating improve insulin sensitivity and sometimes restore ovulation. Several medical options exist for cycle regulation, androgen symptoms and fertility, and the right one depends on your goals.

## Tracking is genuinely useful here
Long cycles are hard to describe from memory. A year of logged start dates is strong evidence, and it also shows whether a treatment is working.

This is background reading. Diagnosis needs a clinician, bloodwork, and the exclusion of conditions that look similar, including thyroid disease and raised prolactin.
''',
  ),
  Article(
    id: 'endometriosis',
    title: 'Endometriosis: The Basics',
    category: ArticleCategory.conditions,
    emoji: '🎗️',
    readMinutes: 6,
    summary: 'When period pain has a structural cause.',
    body: '''
In endometriosis, tissue resembling the uterine lining grows outside the uterus — on the ovaries, the pelvic lining, the bowel or the bladder. It responds to cycle hormones, bleeds where it sits, and provokes inflammation, scarring and adhesions. It affects roughly **one in ten** people of reproductive age.

## Symptoms that point toward it
- Period pain severe enough to disrupt normal activity
- Pelvic pain outside your period
- Deep pain during or after sex
- Pain with bowel movements or urination, often worse around a period
- Heavy or irregular bleeding
- Marked fatigue
- Difficulty conceiving

Severity of symptoms does not track the amount of tissue found. Extensive disease can be quiet, and small deposits can be agonising.

## Why diagnosis is slow
Delays of several years remain common. Period pain is normalised, symptoms overlap with bowel conditions, and imaging can look clean while disease is present. Laparoscopy is the definitive answer, though many clinicians now begin treatment on symptoms alone.

## Management, in outline
Care usually combines pain management, hormonal approaches that suppress cyclical activity, surgical excision, and pelvic physiotherapy for the muscle guarding that chronic pain creates. There is no cure, but well-managed endometriosis is a different life from unmanaged endometriosis.

## Make your case with data
Take a pain and symptom log to your appointment: cycle day, score, and what it stopped you doing. Written records shift conversations that verbal accounts often do not.

Educational only. Persistent pelvic pain deserves a clinician who takes it seriously, and asking for a second opinion is reasonable.
''',
  ),
  Article(
    id: 'thyroid-cycle',
    title: 'Thyroid and Your Cycle',
    category: ArticleCategory.conditions,
    emoji: '🦋',
    readMinutes: 4,
    summary: 'A small gland with a large influence on periods.',
    body: '''
Thyroid hormones set the metabolic pace of the whole body, including the reproductive axis. Thyroid disorders are several times more common in women than men, and a change in periods is often the first visible sign.

## Underactive thyroid
Hypothyroidism tends to bring heavier and longer periods, shorter cycles, or cycles without ovulation. Other clues include fatigue, cold intolerance, constipation, dry skin, hair thinning and unexplained weight gain.

## Overactive thyroid
Hyperthyroidism tends to bring lighter, shorter or absent periods. Other clues include heat intolerance, palpitations, tremor, anxiety, disturbed sleep and weight loss despite a normal appetite.

## Overlaps that cause confusion
Thyroid symptoms overlap heavily with PMS, PCOS, anaemia, perimenopause and depression. That overlap is exactly why thyroid function tests are usually part of the first round of investigation when cycles change.

## Worth raising
A clear change in flow or cycle length that persists for three or more cycles, particularly alongside energy, temperature, weight or mood changes. Thyroid function is a straightforward blood test.

If you are pregnant or planning to be, thyroid status matters more, and it is worth asking about directly.
''',
  ),

  // ── Wellbeing ─────────────────────────────────────────────────────────────
  Article(
    id: 'sleep-cycle',
    title: 'Sleep Across Your Cycle',
    category: ArticleCategory.wellbeing,
    emoji: '😴',
    readMinutes: 4,
    summary: 'Why the same routine sleeps differently in week four.',
    body: '''
Sleep quality is not constant across a cycle, and the reason is partly thermal.

## The luteal phase runs warmer
Progesterone raises core temperature slightly. A **falling** core temperature is one of the signals that initiates sleep, so a warmer baseline makes falling asleep harder and fragments the night. Many people also report more vivid dreams and more night waking in the premenstrual week.

## The first days of bleeding
Pain, prostaglandins and iron loss all interfere. Cramping that is manageable during the day becomes the reason you are awake at three in the morning.

## Around ovulation
Sleep is often at its best in the late follicular phase, when oestrogen is high and temperature is still low.

## Adjustments that respect the physiology
- Keep the bedroom cooler in the luteal week rather than keeping the routine identical
- Hold a consistent wake time, which anchors the body clock more strongly than bedtime does
- Move caffeine earlier if you are more sensitive premenstrually
- Treat pain before bed rather than after it wakes you
- Get morning daylight, which strengthens the same clock

## The loop worth breaking
Short sleep raises pain sensitivity and worsens mood, which then worsens sleep. Protecting the luteal week deliberately is easier than recovering from it.
''',
  ),
  Article(
    id: 'movement-cycle',
    title: 'Training With Your Cycle',
    category: ArticleCategory.wellbeing,
    emoji: '🏃',
    readMinutes: 5,
    summary: 'Adjusting load without giving up consistency.',
    body: '''
Consistency beats optimisation. The strongest finding in this area is that **regular aerobic exercise reduces period pain** and improves premenstrual mood. Phase-based programming is a refinement on top of that, and the evidence is still developing.

## What changes across the month
- **Follicular phase:** many people tolerate higher intensity and heavier loads well
- **Around ovulation:** strength is often at its peak; joint laxity may increase slightly, so technique deserves attention
- **Luteal phase:** higher core temperature and heart rate make hard sessions feel harder; heat tolerance drops and fuelling needs rise
- **Menstrual phase:** performance is often intact even when motivation is not — plenty of athletes compete and win here

## A reasonable approach
Rather than following a template, log your sessions alongside your cycle for two or three months and look at your own perceived effort. Individual variation is larger than the average phase effect.

## A signal to take seriously
Losing your period while training hard, one component of relative energy deficiency in sport, is not a sign of fitness. It indicates energy intake is not covering output, and it carries real consequences for bone density and long-term health. That warrants a clinician and usually a sports dietitian.

## On heavy days
Walking, mobility work and easy cycling are legitimate training. Movement generally reduces cramping rather than worsening it.
''',
  ),
  Article(
    id: 'stress-late',
    title: 'Stress and a Late Period',
    category: ArticleCategory.wellbeing,
    emoji: '🧘',
    readMinutes: 4,
    summary: 'How pressure delays ovulation, and therefore your period.',
    body: '''
A late period after a hard month is usually not a mystery. Sustained stress acts on the hypothalamus, which sets the rhythm the whole reproductive axis follows.

## The mechanism
The hypothalamus releases gonadotropin-releasing hormone in pulses. Chronic stress, undereating, heavy training loads, illness and severe sleep loss slow those pulses. Ovulation is postponed, sometimes by a week or more, and the period arrives late because the luteal phase only begins **after** ovulation. The luteal phase itself stays fairly fixed.

## Which means
- A delayed period usually reflects delayed ovulation
- A cycle can be long without anything being wrong
- If ovulation is delayed, a fertile window predicted from an average is off too

## When absence needs attention
Three or more consecutive missed cycles without pregnancy is called secondary amenorrhoea and deserves assessment. Do not assume stress explains it — thyroid disease, raised prolactin, PCOS and low energy availability all present this way.

## Also worth remembering
Take a pregnancy test if pregnancy is possible. It is the fastest way to remove the most common explanation.

## What actually lowers the load
Regular sleep and wake times, eating enough, daylight, movement you enjoy, and treating recovery as part of the plan. Breathing and mindfulness practices have reasonable evidence for perceived stress, which is the part that keeps the loop going.
''',
  ),
];

// ─── Library screen ──────────────────────────────────────────────────────────

class EducationScreen extends ConsumerStatefulWidget {
  const EducationScreen({super.key});

  @override
  ConsumerState<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<EducationScreen> {
  final _searchController = TextEditingController();

  String _query = '';
  ArticleCategory? _category;
  bool _savedOnly = false;
  bool _disclaimerDismissed = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Article> _visible(List<String> bookmarks) {
    final needle = _query.trim().toLowerCase();
    return kArticles.where((article) {
      if (_category != null && article.category != _category) return false;
      if (_savedOnly && !bookmarks.contains(article.id)) return false;
      return article.matches(needle);
    }).toList();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = null;
      _savedOnly = false;
    });
  }

  void _open(Article article) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _ArticleScreen(article: article)),
    );
  }

  void _toggleBookmark(Article article) {
    final added = ref.read(educationBookmarksProvider.notifier).toggle(article.id);
    showAppToast(
      context,
      message: added
          ? 'Saved to your bookmarks'
          : 'Removed from your bookmarks',
      kind: added ? ToastKind.success : ToastKind.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = ref.watch(educationBookmarksProvider);
    final read = ref.watch(educationProgressProvider);
    final visible = _visible(bookmarks);
    final filtered = _query.trim().isNotEmpty || _category != null || _savedOnly;

    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        title: const Text('Learn'),
        actions: [
          if (filtered)
            IconButton(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded),
              tooltip: 'Clear filters',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: _SearchField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                SelectableChip(
                  label: 'All',
                  emoji: '📚',
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                for (final category in ArticleCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SelectableChip(
                      label: category.label,
                      emoji: category.emoji,
                      accent: category.tone(context),
                      selected: _category == category,
                      onSelected: (selected) => setState(
                        () => _category = selected ? category : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: _ResultsSummary(
                    count: visible.length,
                    readCount: read.length,
                    total: kArticles.length,
                  ),
                ),
                const SizedBox(width: 10),
                SelectableChip(
                  label: bookmarks.isEmpty ? 'Saved' : 'Saved ${bookmarks.length}',
                  icon: Icons.bookmark_rounded,
                  selected: _savedOnly,
                  onSelected: (value) => setState(() => _savedOnly = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? EmptyState(
                    emoji: _savedOnly && bookmarks.isEmpty ? '🔖' : '🔍',
                    title: _savedOnly && bookmarks.isEmpty
                        ? 'Nothing saved yet'
                        : 'No articles match',
                    message: _savedOnly && bookmarks.isEmpty
                        ? 'Tap the bookmark on any article and it will wait for you here, even after you close the app.'
                        : 'Try a shorter search, a different category, or clear the filters to see all ${kArticles.length} articles.',
                    actionLabel: 'Clear filters',
                    onAction: _clearFilters,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 32),
                    itemCount: visible.length + (_disclaimerDismissed ? 0 : 1),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (!_disclaimerDismissed && index == 0) {
                        return Reveal(
                          child: InfoBanner(
                            icon: Icons.local_library_rounded,
                            title: 'Educational, not medical advice',
                            message:
                                'These articles explain how things generally work. They cannot assess your body — bring anything that worries you to a clinician.',
                            onDismiss: () =>
                                setState(() => _disclaimerDismissed = true),
                          ),
                        );
                      }
                      final position =
                          _disclaimerDismissed ? index : index - 1;
                      final article = visible[position];
                      return Reveal(
                        // Capped so the last card in a long list is never left
                        // visibly waiting its turn.
                        index: position.clamp(0, 8),
                        child: _ArticleCard(
                          article: article,
                          bookmarked: bookmarks.contains(article.id),
                          read: read.contains(article.id),
                          onTap: () => _open(article),
                          onBookmark: () => _toggleBookmark(article),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Library pieces ──────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.lineColor),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: context.inkColor,
        ),
        decoration: InputDecoration(
          filled: false,
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintText: 'Search cramps, iron, ovulation…',
          hintStyle: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: context.subtleColor,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: context.mutedColor,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return Pressable(
                scale: 0.88,
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.cancel_rounded,
                    size: 18,
                    color: context.subtleColor,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({
    required this.count,
    required this.readCount,
    required this.total,
  });

  final int count;
  final int readCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count == total
              ? '$total articles'
              : '$count of $total articles',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.1,
            color: context.inkColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          readCount == 0
              ? 'Nothing read yet — start anywhere'
              : '$readCount read',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: context.mutedColor,
          ),
        ),
      ],
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
    required this.bookmarked,
    required this.read,
    required this.onTap,
    required this.onBookmark,
  });

  final Article article;
  final bool bookmarked;
  final bool read;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final tone = article.category.tone(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.withOpacity(context.isDark ? 0.20 : 0.11),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(article.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaRow(article: article, read: read),
                const SizedBox(height: 5),
                Text(
                  article.title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: context.inkColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: context.mutedColor,
                  ),
                ),
              ],
            ),
          ),
          _BookmarkButton(
            bookmarked: bookmarked,
            onTap: onBookmark,
            tone: tone,
          ),
        ],
      ),
    );
  }
}

/// Category name, reading time, and a read tick — the three things that decide
/// whether a card is worth opening right now.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.article, required this.read});

  final Article article;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final tone = article.category.tone(context);

    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tone.withOpacity(context.isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              article.category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                color: tone,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.schedule_rounded, size: 12, color: context.subtleColor),
        const SizedBox(width: 3),
        Text(
          '${article.readMinutes} min',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.subtleColor,
          ),
        ),
        if (read) ...[
          const SizedBox(width: 8),
          const Icon(
            Icons.check_circle_rounded,
            size: 12,
            color: AppColors.success,
          ),
          const SizedBox(width: 3),
          const Text(
            'Read',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ],
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({
    required this.bookmarked,
    required this.onTap,
    required this.tone,
  });

  final bool bookmarked;
  final VoidCallback onTap;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.86,
      child: Padding(
        // Padding rather than a smaller icon: the tap target stays comfortable
        // while the glyph stays quiet next to the title.
        padding: const EdgeInsets.all(8),
        child: AnimatedSwitcher(
          duration: AppDurations.micro,
          switchInCurve: AppCurves.out,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            key: ValueKey<bool>(bookmarked),
            size: 21,
            color: bookmarked ? tone : context.subtleColor,
          ),
        ),
      ),
    );
  }
}

// ─── Article screen ──────────────────────────────────────────────────────────

class _ArticleScreen extends ConsumerStatefulWidget {
  const _ArticleScreen({required this.article});

  final Article article;

  @override
  ConsumerState<_ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<_ArticleScreen> {
  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame: writing provider state during the
    // build that opened this route would rebuild the list underneath us
    // mid-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(educationProgressProvider.notifier).markRead(widget.article.id);
    });
  }

  void _toggleBookmark() {
    final added =
        ref.read(educationBookmarksProvider.notifier).toggle(widget.article.id);
    showAppToast(
      context,
      message: added ? 'Saved to your bookmarks' : 'Removed from your bookmarks',
      kind: added ? ToastKind.success : ToastKind.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final tone = article.category.tone(context);
    final bookmarked = ref.watch(educationBookmarksProvider).contains(article.id);

    final related = kArticles
        .where((other) =>
            other.category == article.category && other.id != article.id)
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        title: Text(
          article.category.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.mutedColor,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleBookmark,
            tooltip: bookmarked ? 'Remove bookmark' : 'Save article',
            icon: Icon(
              bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: bookmarked ? tone : context.mutedColor,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 40),
        children: [
          Reveal(
            child: Container(
              width: 68,
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.withOpacity(context.isDark ? 0.20 : 0.11),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(article.emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 18),
          Reveal(
            index: 1,
            child: Text(
              article.title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.18,
                letterSpacing: -0.4,
                color: context.inkColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Reveal(
            index: 2,
            child: Text(
              article.summary,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: context.mutedColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            index: 2,
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: tone),
                const SizedBox(width: 5),
                Text(
                  '${article.readMinutes} min read',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: tone,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: context.lineColor),
          ),
          Reveal(index: 3, child: _ArticleBody(body: article.body, tone: tone)),
          const SizedBox(height: 26),
          const InfoBanner(
            icon: Icons.medical_information_rounded,
            title: 'Educational information only',
            message:
                'This article describes how things generally work. It is not a diagnosis, a treatment plan, or a substitute for a clinician who can examine you.',
            tone: AppColors.info,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: bookmarked ? 'Saved to bookmarks' : 'Save for later',
            icon: bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            outlined: true,
            onPressed: _toggleBookmark,
          ),
          if (related.isNotEmpty) ...[
            const SizedBox(height: 30),
            SectionHeader(
              title: 'More on ${article.category.label.toLowerCase()}',
              subtitle: 'Related reading',
              padding: const EdgeInsets.only(bottom: 12),
            ),
            for (final other in related)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ActionTile(
                  icon: Icons.article_rounded,
                  emoji: other.emoji,
                  title: other.title,
                  subtitle: '${other.readMinutes} min read',
                  accent: tone,
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => _ArticleScreen(article: other),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Renders the light markup used in [Article.body].
///
/// A real Markdown package would be heavier than the four constructs actually
/// used here, and would drag in its own typography that fights the design
/// system. Body copy is set at 15px with generous leading because these are
/// several-hundred-word reads, not labels.
class _ArticleBody extends StatelessWidget {
  const _ArticleBody({required this.body, required this.tone});

  final String body;
  final Color tone;

  static const _bodySize = 15.0;
  static const _bodyHeight = 1.65;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: _bodySize,
      fontWeight: FontWeight.w500,
      height: _bodyHeight,
      color: context.inkColor.withOpacity(context.isDark ? 0.90 : 0.86),
    );
    final strong = base.copyWith(
      fontWeight: FontWeight.w800,
      color: context.inkColor,
    );

    final blocks = <Widget>[];
    var first = true;

    for (final raw in body.trim().split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('## ')) {
        blocks.add(Padding(
          padding: EdgeInsets.only(top: first ? 0 : 22, bottom: 8),
          child: Text(
            line.substring(3),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.3,
              letterSpacing: -0.1,
              color: context.inkColor,
            ),
          ),
        ));
      } else if (line.startsWith('- ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // Nudged down onto the first line's optical centre.
                padding: const EdgeInsets.only(top: 8, right: 11, left: 2),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: tone,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(children: _inline(line.substring(2), base, strong)),
                ),
              ),
            ],
          ),
        ));
      } else {
        blocks.add(Padding(
          padding: EdgeInsets.only(top: first ? 0 : 2, bottom: 12),
          child: Text.rich(TextSpan(children: _inline(line, base, strong))),
        ));
      }
      first = false;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }

  /// Splits on `**` and alternates between [base] and [strong]. Odd segments
  /// are the emphasised ones, which means an unclosed marker degrades to bold
  /// tail text rather than throwing.
  List<TextSpan> _inline(String source, TextStyle base, TextStyle strong) {
    final parts = source.split('**');
    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(text: parts[i], style: i.isOdd ? strong : base));
    }
    return spans;
  }
}
