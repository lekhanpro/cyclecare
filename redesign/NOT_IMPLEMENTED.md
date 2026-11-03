# Planned features — implement these before the UI is called functional

**Historical handoff snapshot:** expanded logging fields and interactive Home
controls described below have since gained Flutter domain/storage/UI support.
The [v2.2.0 implementation record](../docs/release-verification.md) describes
current behavior and evidence. Natural companion mesh/film integration remains
pending. Catalogue flags preserve the original source inspection and must not
be used to infer current feature availability.

The latest [natural pet motion](NATURAL_PET_MOTION.md)—MP4 playback, continuous-image mesh and live finger responses—is also **not implemented in Flutter**. The browser prototype includes these interactions and local assets; production needs platform playback/lifecycle, caching, touch/accessibility integration and real-device performance checks.

The redesigned controls below include features that are **not yet implemented in the Flutter app**. Implement their data model, local persistence, validation, migration, export/restore and meaningful tests first. Then build and connect the approved UI/UX. Keep all future additions consistent with this design and its fluid/reduced-motion behaviour.

“Existing” means the inspected current model or active UI supports that field/choice; it does not mean its new browser control is wired into Flutter. “Planned” means the field or choice needs actual product work. Do not confuse inactive legacy constants with implemented UI.

Current active sources: `tracking_options.dart` (10 moods, 16 symptoms), `cycle_models.dart:DailyLog` (17 persisted fields including date), and the current log screen/custom-tag controller. The JSON catalogue contains precise per-option evidence.

The interactive Home cycle dial, direct graph scrubbing, hormone focus/readouts, phase zoom, chart expansion and separate companion Play/Pause controls are also browser prototype designs awaiting the Flutter port. The hormone graph requires source-reviewed educational content and accessible interaction; its synthetic curves must never become stored health records, measured levels or personal hormone predictions. These UI additions do not add logging fields or change the catalogue counts. See [the Home implementation requirements](IMPLEMENTATION_PLAN.md#interactive-home-circle-and-hormone-education).


The articulated companion browser actions are also pending the Flutter port. Breathing guidance, held-prop feedback and helpful navigation are demonstrated in the prototype. Automatic reminders, saved hydration, real XP and production event triggers must be wired to their actual local domain behavior. The supplied native Rive assets have four verified states, fewer than the browser's complete action set; complete the remaining states and runtime integration before claiming parity. See [PET_ANIMATION.md](PET_ANIMATION.md).

## Required foundations

- Preserve every old record and custom symptom tag when migrating. Do not invent observations for missing fields.
- Make not logged/null, explicit none/zero, and unknown/not sure distinct. Address current default-value ambiguity in pain, water and medication records.
- Add storage and validation for planned body/height, pain location, sleep quality/energy, exercise/nourishment, intimacy/protection/libido, reproductive tests and structured medication/care additions.
- Add expanded options deliberately; preserve backward compatibility and exports. Do not claim expanded legacy lists are already wired.
- Keep sensitive logging and future analyses local by default; implement consent before any explicit sharing.
- Then connect the same accordion, selection summary, icon, date, save/error and reduced-motion patterns across all relevant screens.

## Field status

| Group | Field | Status | Existing / planned choices |
| --- | --- | --- | --- |
| Flow | Flow (`flow`) | implemented | 5 / 1 |
| How are you feeling? | Mood (`mood`) | implemented | 10 / 44 |
| Symptoms & little signals | Aches & body signals (`symptomsBody`) | implemented | 6 / 15 |
| Symptoms & little signals | Digestion & appetite (`symptomsDigestion`) | implemented | 4 / 7 |
| Symptoms & little signals | Skin & changes (`symptomsSkin`) | implemented | 1 / 8 |
| Symptoms & little signals | Rest, energy & temperature (`symptomsRest`) | implemented | 5 / 7 |
| Pain & comfort | Pain level (`painLevel`) | implemented | 11 / 0 |
| Pain & comfort | Where you feel it (`painLocation`) | planned | 0 / 6 |
| Discharge & fertility signs | Discharge (`discharge`) | implemented | 6 / 3 |
| Discharge & fertility signs | Cervical mucus (`cervicalMucus`) | implemented | 5 / 0 |
| Discharge & fertility signs | Cervical position (`cervicalPosition`) | implemented | 3 / 0 |
| Discharge & fertility signs | Cervical firmness (`cervicalFirmness`) | implemented | 3 / 0 |
| Discharge & fertility signs | Cervical opening (`cervicalOpening`) | implemented | 3 / 0 |
| Body measurements | Basal body temperature (`temperatureCelsius`) | implemented | 0 / 0 |
| Body measurements | Weight (`weightKg`) | implemented | 0 / 0 |
| Body measurements | Height (`heightCm`) | planned | 0 / 0 |
| Sleep, water & energy | Sleep (`sleepHours`) | implemented | 0 / 0 |
| Sleep, water & energy | Water (`waterMl`) | implemented | 0 / 0 |
| Sleep, water & energy | Sleep quality (`sleepQuality`) | planned | 0 / 4 |
| Sleep, water & energy | Your energy (`energy`) | planned | 0 / 3 |
| Movement & nourishment | Movement (`exerciseType`) | planned | 0 / 10 |
| Movement & nourishment | Time moving (`exerciseMinutes`) | planned | 0 / 0 |
| Movement & nourishment | Appetite (`appetite`) | planned | 0 / 4 |
| Intimacy & protection | Intimacy (`intimacy`) | planned | 0 / 5 |
| Intimacy & protection | Protection used (`protection`) | planned | 0 / 5 |
| Intimacy & protection | Sex drive (`libido`) | planned | 0 / 4 |
| Tests & observations | Pregnancy test (`pregnancyTest`) | planned | 0 / 4 |
| Tests & observations | Ovulation test (`ovulationTest`) | planned | 0 / 4 |
| Tests & observations | Test note (`testNote`) | planned | 0 / 0 |
| Medication & care | Medication today (`medicineTaken`) | implemented | 2 / 0 |
| Medication & care | Medication name (`medicineName`) | implemented | 0 / 0 |
| Medication & care | Dose as prescribed (`medicineDose`) | planned | 0 / 0 |
| Medication & care | Comfort & care (`careActions`) | planned | 0 / 6 |
| Your words & custom tags | A little note (`notes`) | implemented | 0 / 0 |
| Your words & custom tags | Your own symptoms (`customTags`) | implemented | 0 / 0 |

## Every planned option

### Flow

- **Flow:** Very heavy.

### How are you feeling?

- **Mood:** Tired, Mood swings, Confident, Confusion, Tension, Sleepy, Exhausted, Normal, Depressed, Surprised, Worried, Stunned, Accomplished, Smug, Indifferent, Sexy, Assertive, Impatient, Pensive, Weird, Excited, Hopeful, Horny, In love, Peaceful, Playful, Proud, Relaxed, Satisfied, Silly, Hyped, Jealous, Frustrated, Angry, Grumpy, Cranky, Disappointed, Tormented, Insecure, Bored, Lonely, Panicky, Ashamed, Ill.

### Symptoms & little signals

- **Aches & body signals:** Migraine, Joint pain, Muscle pain, Lower back tension, Pelvic pressure, Weight gain, Body aches, Breast sensitivity, Neck pain, Shoulder pain, Ovulation pain, Bleeding, Breast texture changes, Vaginal dryness, Vaginal irritation.
- **Digestion & appetite:** Constipation, Diarrhea, Appetite changes, Heartburn, Flatulence, Hunger, Stomach pain.
- **Skin & changes:** Spotting, Oily skin, Dry skin, Skin sensitivity, Hair changes, Clear skin, Itchiness, Skin rash.
- **Rest, energy & temperature:** Low energy, Brain fog, Chills, Feeling warm, Fever, Poor sleep, Sickness.

### Pain & comfort

- **Where you feel it:** Lower belly, Lower back, Head, Breasts, Joints, Other.

### Discharge & fertility signs

- **Discharge:** Egg-white, With blood, Green.

### Sleep, water & energy

- **Sleep quality:** Restful, Light sleep, Restless, Interrupted.
- **Your energy:** Low, Steady, High.

### Movement & nourishment

- **Movement:** Walking, Running, Yoga, Swimming, Cycling, Strength, Pilates, Dancing, HIIT, Other.
- **Appetite:** Less than usual, As usual, More than usual, Cravings.

### Intimacy & protection

- **Intimacy:** None, Partnered, Solo, Prefer not to say, Kissing.
- **Protection used:** Condom, Regular method, Other, None, Not sure.
- **Sex drive:** Low, Usual, High, Not sure.

### Tests & observations

- **Pregnancy test:** Positive, Negative, Unclear, Not taken.
- **Ovulation test:** Positive, Negative, Unclear, Not taken.

### Medication & care

- **Comfort & care:** Heat pad, Rest, Stretching, Breathing, A little walk, Other.

## Design and implementation are separate

The screenshot collection covers all 60 named screen designs and both appearances. It is not a completed Flutter port. Follow [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md), preserve all existing app elements, and update this status as real implementation evidence changes.
