import 'package:flutter/material.dart';

import '../../../core/theme/cyclecare_theme.dart';
import 'article.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The articles that existed before the typed-body migration
//
// Preserved against test/fixtures/pre_migration_articles.json.
// The fixture was extracted from the previous
// `_kOriginalArticles` in education_screen.dart and `kNewArticles` in
// new_articles.dart, and the migration test compares this list against it
// field by field — so an edit here that changes a word will fail the build
// until the fixture is updated deliberately.
//
// Edit the content by editing this file and the fixture together. The
// generator exists to make the one-time migration verifiable, not to make the
// content read-only.
//
// Content rules, unchanged: describe mechanisms, name the symptoms worth
// escalating, and stop there. No dosages, no diagnoses, no "you have".
// ─────────────────────────────────────────────────────────────────────────────

/// The 26 articles carried over from before the migration, in their original
/// order.
final List<Article> kCoreArticles = List.unmodifiable(<Article>[
  Article(
    id: 'cycle-phases',
    title: 'The Four Phases of Your Cycle',
    category: ArticleCategory.basics,
    icon: AppIcons.cycle,
    readMinutes: 6,
    standfirst: 'What actually happens across a month, stage by stage.',
    body: '''Your cycle is one continuous hormonal loop, but it is easier to read in four stages. Day 1 is the first day of real bleeding, not spotting.

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

Log a few cycles and CycleCare fits these estimates to your own pattern rather than a textbook 28 days.''',
  ),
  Article(
    id: 'cycle-length',
    title: 'What Counts as a Normal Cycle',
    category: ArticleCategory.basics,
    icon: AppIcons.calendarRange,
    readMinutes: 4,
    standfirst: 'The normal range is wider than most people are told.',
    body: '''A cycle is measured from the first day of one period to the day before the next. Anything from **21 to 35 days** is considered typical for adults, and 21 to 45 days in the first few years after periods begin.

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

This is general education, not a diagnosis. Bring your logged history to an appointment — a real record is far more useful than recall.''',
  ),
  Article(
    id: 'reading-flow',
    title: 'Reading Your Flow',
    category: ArticleCategory.basics,
    icon: AppIcons.period,
    readMinutes: 4,
    standfirst: 'Colour, volume and clots — what is ordinary and what is not.',
    body: '''Total blood loss across a typical period is roughly **30 to 80 ml**, which is far less than it looks like. Most of what you see is a mix of blood, lining tissue and cervical fluid.

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

Educational only — no article can assess your bleeding for you.''',
  ),
  Article(
    id: 'hormones-101',
    title: 'The Hormones Running the Show',
    category: ArticleCategory.basics,
    icon: AppIcons.microscope,
    readMinutes: 5,
    standfirst: 'Four messengers, and what each one is doing.',
    body: '''Four hormones do most of the work, in a feedback loop between the brain and the ovaries.

## FSH, follicle-stimulating hormone
Released by the pituitary early in the cycle. It recruits follicles and starts the race toward ovulation.

## Oestrogen
Produced by the growing follicle. It thickens the uterine lining, thins cervical mucus so sperm can travel, and supports mood, skin and bone. It climbs through the follicular phase and peaks just before ovulation.

## LH, luteinising hormone
Also from the pituitary. A sharp surge in LH is the trigger that releases the egg. Ovulation predictor strips are looking for exactly this.

## Progesterone
Made by the corpus luteum after ovulation. It quiets uterine contractions, holds the lining in place, raises basal temperature slightly and has a calming, sometimes sedating effect. Its **withdrawal** at the end of the luteal phase is what starts a period.

## Why this matters for tracking
Symptoms cluster where hormones move fastest: the days before a period, and the day or two around ovulation. If your logs show a pattern locked to one of those windows, that is a signal rather than a coincidence.''',
  ),
  Article(
    id: 'fertile-window',
    title: 'The Fertile Window',
    category: ArticleCategory.fertility,
    icon: AppIcons.fertile,
    readMinutes: 4,
    standfirst: 'When conception is actually possible.',
    body: '''Sperm can survive up to five days in fertile cervical mucus. An egg lives 12 to 24 hours. Together that gives a window of roughly **six days**.

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

CycleCare sharpens its estimate with every cycle you log.''',
  ),
  Article(
    id: 'bbt',
    title: 'Basal Body Temperature',
    category: ArticleCategory.fertility,
    icon: AppIcons.temperature,
    readMinutes: 5,
    standfirst: 'A quiet daily number that confirms ovulation happened.',
    body: '''Basal body temperature is your lowest resting temperature, taken before you sit up, speak or drink anything.

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
BBT is retrospective. It confirms ovulation after it happens, so on its own it cannot tell you your fertile days are starting. Pair it with cervical mucus for a forward-looking signal.''',
  ),
  Article(
    id: 'cervical-mucus',
    title: 'Cervical Mucus as a Signal',
    category: ArticleCategory.fertility,
    icon: AppIcons.water,
    readMinutes: 4,
    standfirst: 'The most useful real-time fertility sign you already have.',
    body: '''Cervical mucus changes across the cycle under oestrogen, and unlike temperature it changes **before** ovulation rather than after.

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
Persistent itching, unusual colour, a strong odour, or pain alongside changed discharge points toward infection rather than a cycle change, and deserves a clinical opinion.''',
  ),
  Article(
    id: 'lh-tests',
    title: 'Ovulation Tests and the LH Surge',
    category: ArticleCategory.fertility,
    icon: AppIcons.science,
    readMinutes: 4,
    standfirst: 'How strips work, and the four ways they mislead.',
    body: '''Ovulation predictor kits detect luteinising hormone in urine. LH climbs sharply **24 to 36 hours before** the egg is released, so a positive test points at the most fertile days ahead.

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

Strips are a planning tool. Persistent difficulty conceiving, or results that never turn positive across several cycles, deserves a conversation with a clinician rather than more tests.''',
  ),
  Article(
    id: 'cramps',
    title: 'Why Cramps Happen',
    category: ArticleCategory.symptoms,
    icon: AppIcons.cramps,
    readMinutes: 5,
    standfirst: 'The mechanism behind period pain, and what tends to help.',
    body: '''Before a period, the uterine lining releases **prostaglandins**. These make the uterus contract to shed the lining, and they also constrict local blood vessels. Strong contractions plus briefly reduced blood flow is what you feel as cramping.

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

Educational only, and deliberately without specific medicines or doses.''',
  ),
  Article(
    id: 'pms-pmdd',
    title: 'PMS and PMDD',
    category: ArticleCategory.symptoms,
    icon: AppIcons.pms,
    readMinutes: 5,
    standfirst: 'Where premenstrual symptoms cross into a disorder.',
    body: '''Both sit in the luteal phase and both ease within a few days of bleeding starting. The difference is severity and impact.

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

If premenstrual weeks bring thoughts of self-harm, treat that as urgent and contact a health professional or a local crisis line rather than waiting for the next cycle.''',
  ),
  Article(
    id: 'cycle-headaches',
    title: 'Cycle Headaches and Migraine',
    category: ArticleCategory.symptoms,
    icon: AppIcons.headache,
    readMinutes: 4,
    standfirst: 'Why some headaches track your hormones.',
    body: '''For many people headaches cluster in a narrow window: the two days before a period and the first three days of it. The trigger appears to be the **drop** in oestrogen rather than any particular level.

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
A sudden severe headache unlike any before, headache with fever or a stiff neck, new neurological symptoms, or aura appearing for the first time while using combined hormonal contraception.''',
  ),
  Article(
    id: 'eating-with-cycle',
    title: 'Eating Across Your Cycle',
    category: ArticleCategory.nutrition,
    icon: AppIcons.nutrition,
    readMinutes: 5,
    standfirst: 'Small shifts that match what your body is doing.',
    body: '''Nothing here is a diet. Total intake and overall quality matter far more than phase-specific tweaks. That said, needs do shift.

## Menstrual phase
Iron losses are real, so iron-rich foods earn their place: lentils, beans, tofu, dark leafy greens, red meat if you eat it. Vitamin C in the same meal improves absorption of plant iron. Magnesium-rich foods such as nuts, seeds and dark chocolate are often mentioned for cramps.

## Follicular phase
Rising oestrogen and generally better energy suit ordinary, protein-adequate meals. Fibre and fermented foods support the gut bacteria involved in clearing oestrogen.

## Around ovulation
Colourful plants, olive oil, oily fish, nuts. Zinc and dietary antioxidants are involved in reproductive function.

## Luteal phase
Resting metabolic rate rises modestly and appetite often follows — that is physiology, not weakness. Complex carbohydrates with protein help steady mood and blood sugar. Cutting back on very salty food reduces the fluid retention behind premenstrual bloating.

## Two honest caveats
Evidence for phase-based eating is thinner than the internet suggests, and individual needs vary a great deal. Anyone with anaemia, a restrictive eating history or a diagnosed condition should work with a clinician or registered dietitian rather than a general article.''',
  ),
  Article(
    id: 'iron-energy',
    title: 'Iron, Blood Loss and Energy',
    category: ArticleCategory.nutrition,
    icon: Icons.bloodtype_rounded,
    readMinutes: 4,
    standfirst: 'Why heavy periods and exhaustion travel together.',
    body: '''Every period costs iron. With heavy or long bleeding, monthly losses can outpace what your diet replaces, and stores drain quietly over months.

## What low iron feels like
Fatigue that rest does not fix, breathlessness on stairs, dizziness, cold hands, poor concentration, hair shedding, brittle nails, restless legs, sometimes a craving for ice. Symptoms appear well before a blood count looks abnormal, because **ferritin**, the stored form, falls first.

## Two forms in food
- **Haem iron**, from meat, poultry and fish, is absorbed readily
- **Non-haem iron**, from legumes, tofu, seeds, wholegrains and dark greens, is absorbed less well but improves markedly alongside vitamin C

Tea, coffee and calcium taken with a meal reduce absorption, so timing them away from your main iron-containing meals helps.

## Test before supplementing
Iron supplements are not harmless. Excess iron accumulates and causes damage, and fatigue has many other causes. A ferritin level and full blood count is the right starting point, and dosing is a clinical decision rather than a guess.

## Bring your log
Recorded flow levels and product changes let a clinician judge whether bleeding volume explains the tiredness.''',
  ),
  Article(
    id: 'bloating-fluid',
    title: 'Bloating and Fluid Balance',
    category: ArticleCategory.nutrition,
    icon: AppIcons.bloating,
    readMinutes: 4,
    standfirst: 'Why the luteal week feels tighter, and what helps.',
    body: '''Premenstrual bloating has two separate causes that are easy to confuse.

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
Bloating that does not resolve after your period, or comes with weight loss, blood in stool, vomiting or persistent abdominal pain, needs assessment. Lasting bloating is also one of the vaguer symptoms of ovarian conditions, which is a reason to get persistent changes checked rather than a reason to panic.''',
  ),
  Article(
    id: 'pcos',
    title: 'PCOS: The Basics',
    category: ArticleCategory.conditions,
    icon: AppIcons.conditions,
    readMinutes: 6,
    standfirst: 'A common hormonal condition, often misunderstood.',
    body: '''Polycystic ovary syndrome is among the most common endocrine conditions in people of reproductive age, affecting roughly **8 to 13 percent**, and a large share go undiagnosed.

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

This is background reading. Diagnosis needs a clinician, bloodwork, and the exclusion of conditions that look similar, including thyroid disease and raised prolactin.''',
  ),
  Article(
    id: 'endometriosis',
    title: 'Endometriosis: The Basics',
    category: ArticleCategory.conditions,
    icon: AppIcons.pain,
    readMinutes: 6,
    standfirst: 'When period pain has a structural cause.',
    body: '''In endometriosis, tissue resembling the uterine lining grows outside the uterus — on the ovaries, the pelvic lining, the bowel or the bladder. It responds to cycle hormones, bleeds where it sits, and provokes inflammation, scarring and adhesions. It affects roughly **one in ten** people of reproductive age.

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

Educational only. Persistent pelvic pain deserves a clinician who takes it seriously, and asking for a second opinion is reasonable.''',
  ),
  Article(
    id: 'thyroid-cycle',
    title: 'Thyroid and Your Cycle',
    category: ArticleCategory.conditions,
    icon: Icons.speed_rounded,
    readMinutes: 4,
    standfirst: 'A small gland with a large influence on periods.',
    body: '''Thyroid hormones set the metabolic pace of the whole body, including the reproductive axis. Thyroid disorders are several times more common in women than men, and a change in periods is often the first visible sign.

## Underactive thyroid
Hypothyroidism tends to bring heavier and longer periods, shorter cycles, or cycles without ovulation. Other clues include fatigue, cold intolerance, constipation, dry skin, hair thinning and unexplained weight gain.

## Overactive thyroid
Hyperthyroidism tends to bring lighter, shorter or absent periods. Other clues include heat intolerance, palpitations, tremor, anxiety, disturbed sleep and weight loss despite a normal appetite.

## Overlaps that cause confusion
Thyroid symptoms overlap heavily with PMS, PCOS, anaemia, perimenopause and depression. That overlap is exactly why thyroid function tests are usually part of the first round of investigation when cycles change.

## Worth raising
A clear change in flow or cycle length that persists for three or more cycles, particularly alongside energy, temperature, weight or mood changes. Thyroid function is a straightforward blood test.

If you are pregnant or planning to be, thyroid status matters more, and it is worth asking about directly.''',
  ),
  Article(
    id: 'sleep-cycle',
    title: 'Sleep Across Your Cycle',
    category: ArticleCategory.wellbeing,
    icon: AppIcons.sleep,
    readMinutes: 4,
    standfirst: 'Why the same routine sleeps differently in week four.',
    body: '''Sleep quality is not constant across a cycle, and the reason is partly thermal.

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
Short sleep raises pain sensitivity and worsens mood, which then worsens sleep. Protecting the luteal week deliberately is easier than recovering from it.''',
  ),
  Article(
    id: 'movement-cycle',
    title: 'Training With Your Cycle',
    category: ArticleCategory.wellbeing,
    icon: AppIcons.exercise,
    readMinutes: 5,
    standfirst: 'Adjusting load without giving up consistency.',
    body: '''Consistency beats optimisation. The strongest finding in this area is that **regular aerobic exercise reduces period pain** and improves premenstrual mood. Phase-based programming is a refinement on top of that, and the evidence is still developing.

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
Walking, mobility work and easy cycling are legitimate training. Movement generally reduces cramping rather than worsening it.''',
  ),
  Article(
    id: 'stress-late',
    title: 'Stress and a Late Period',
    category: ArticleCategory.wellbeing,
    icon: AppIcons.wellbeing,
    readMinutes: 4,
    standfirst: 'How pressure delays ovulation, and therefore your period.',
    body: '''A late period after a hard month is usually not a mystery. Sustained stress acts on the hypothalamus, which sets the rhythm the whole reproductive axis follows.

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
Regular sleep and wake times, eating enough, daylight, movement you enjoy, and treating recovery as part of the plan. Breathing and mindfulness practices have reasonable evidence for perceived stress, which is the part that keeps the loop going.''',
  ),
  Article(
    id: 'real-world-cycles',
    title: 'What 600,000 Cycles Showed',
    category: ArticleCategory.basics,
    icon: AppIcons.chart,
    readMinutes: 4,
    standfirst:
        'A large study of real app data, and why 28 days is not the rule.',
    body: '''Most of what people are told about the cycle comes from small clinical studies and a tidy textbook diagram. A 2019 study in **npj Digital Medicine** looked instead at hundreds of thousands of cycles logged in a period-tracking app.

## The 28-day cycle is not the norm
Only a minority of cycles in the data were exactly 28 days long. Cycles a few days either side were just as ordinary, and the typical length shifted gradually with age.

## Most of the variation is before ovulation
The time from ovulation to the next period was fairly steady from cycle to cycle. The stretch before ovulation varied far more. That is why a month with illness, travel or stress can push a period later without anything being wrong.

## What this means for you
A prediction based on your own logged cycles is more useful than one based on a textbook. The more cycles you log, the better CycleCare can fit its estimates to you.

The full paper is linked below.''',
  ),
  Article(
    id: 'irregular-periods',
    title: 'When Your Cycle Is Irregular',
    category: ArticleCategory.basics,
    icon: AppIcons.calendarRange,
    readMinutes: 4,
    standfirst:
        'Some variation is normal. Here is when it is worth a closer look.',
    body: '''An irregular cycle is one where the length changes noticeably from one month to the next. A few days of difference is common and usually not a concern.

## Common reasons a cycle shifts
- The first few years after periods begin, and the years leading up to menopause
- Stress, poor sleep, travel or a change in routine
- Big changes in weight or exercise
- Hormonal contraception, starting or stopping it
- Pregnancy and breastfeeding
- Conditions such as PCOS or thyroid problems

## When to talk to a clinician
It is worth seeking advice if your periods stop for several months and you are not pregnant, if your cycle is often much shorter or longer than usual, or if irregular periods come with heavy bleeding or a lot of pain.

## How logging helps
Bringing a record of your start dates to an appointment turns "my periods are all over the place" into a pattern someone can actually read.''',
  ),
  Article(
    id: 'heavy-periods',
    title: 'Heavy Periods',
    category: ArticleCategory.symptoms,
    icon: Icons.waves_rounded,
    readMinutes: 5,
    standfirst:
        'How to tell if your flow is heavy, and why it is worth checking.',
    body: '''Heavy periods are common and often go unmentioned because people assume their own flow is normal. It is worth knowing the signs, because heavy bleeding can wear down your iron levels over time.

## Signs a period may be heavy
- Needing to change a pad or tampon very often, including through the night
- Using two kinds of protection together
- Passing large clots
- Bleeding through to clothes or bedding
- A period that lasts longer than about a week
- Feeling tired or short of breath around your period

## Why it matters
Losing more blood than your body can replace can lead to iron deficiency. That can show up as tiredness, feeling cold, or being breathless more easily.

## What can help
There are several treatments, from medicines taken during a period to longer-term options. A clinician can talk through what suits you, and may suggest a blood test to check your iron.

Logging your flow each day gives you something concrete to show them.''',
  ),
  Article(
    id: 'perimenopause',
    title: 'Perimenopause: The Years Before Menopause',
    category: ArticleCategory.conditions,
    icon: AppIcons.goalPerimenopause,
    readMinutes: 5,
    standfirst: 'What changes in the lead-up to menopause, and what can help.',
    body: '''Menopause is the point when periods have stopped for a year. The years before it are called perimenopause, and they can begin earlier than many people expect.

## What can change
- Periods becoming irregular, heavier or lighter
- Hot flushes and night sweats
- Poorer sleep
- Changes in mood, anxiety or concentration
- Vaginal dryness

Not everyone has all of these, and how strong they are varies a great deal.

## You can still get pregnant
Ovulation becomes less predictable rather than stopping straight away, so contraception is still needed until a clinician says otherwise.

## What can help
Treatments range from lifestyle changes to hormone therapy. If symptoms are affecting your daily life, it is worth talking to a clinician rather than waiting it out.

Tracking cycle changes and symptoms here can make that conversation easier.''',
  ),
  Article(
    id: 'contraception-basics',
    title: 'Contraception: The Main Types',
    category: ArticleCategory.fertility,
    icon: AppIcons.pill,
    readMinutes: 5,
    standfirst: 'An overview of the options, to make a clinic visit easier.',
    body: '''There are many kinds of contraception, and the right one depends on your health, your plans and what you find easy to use. This is a plain overview, not advice on which to choose.

## Hormonal methods
Pills, the patch, the vaginal ring, the injection, the implant and the hormonal coil. They work mainly by stopping ovulation or thickening cervical mucus.

## Non-hormonal methods
The copper coil, condoms, diaphragms and caps. Condoms are the only method that also protects against sexually transmitted infections.

## Long-acting methods
The implant and the coils last for years once fitted and do not depend on remembering anything day to day.

## Fertility awareness
Tracking natural signs to avoid sex on fertile days. It needs careful daily observation and works best when taught by a trained practitioner.

## Choosing
How well each method works depends a lot on how it is used. A clinic or pharmacist can help you compare options for your situation.''',
  ),
  Article(
    id: 'fertility-awareness',
    title: 'Fertility Awareness and Cycle Apps',
    category: ArticleCategory.fertility,
    icon: AppIcons.fertile,
    readMinutes: 4,
    standfirst:
        'Why a predicted fertile window is not a method of contraception.',
    body: '''Fertility awareness means watching your body's own signs, such as temperature and cervical mucus, to work out when you are likely to be fertile.

## What CycleCare's fertile window is
It is an **estimate** based on your past cycle lengths. It does not measure ovulation, and ovulation can move from month to month.

## Why that matters for contraception
Using a calendar estimate on its own to avoid pregnancy is not reliable. Fertility awareness methods used as contraception combine several daily signs, need careful record keeping, and are best learned from a trained practitioner.

## What the estimate is good for
- Getting a feel for your own pattern
- Planning around likely symptoms
- Giving you a starting point if you are trying to conceive

If you want to avoid pregnancy, talk to a clinic about a method that suits you.''',
  ),
]);
