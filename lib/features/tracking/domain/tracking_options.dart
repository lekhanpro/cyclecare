const symptomOptions = [
  'Cramps',
  'Headache',
  'Acne',
  'Bloating',
  'Fatigue',
  'Nausea',
  'Back pain',
  'Cravings',
  'Tender breasts',
  'Dizziness',
  'Digestive changes',
  'Sleep changes',
  'Hot flashes',
  'Night sweats',
  'Pelvic discomfort',
  'Insomnia',
];

const moodOptions = [
  'Happy',
  'Sad',
  'Anxious',
  'Irritable',
  'Calm',
  'Energetic',
  'Emotional',
  'Focused',
  'Stressed',
  'Sensitive',
];

const cervicalMucusOptions = ['Dry', 'Sticky', 'Creamy', 'Watery', 'Egg-white'];

const cervicalPositionOptions = ['Low', 'Medium', 'High'];
const cervicalFirmnessOptions = ['Firm', 'Medium', 'Soft'];
const cervicalOpeningOptions = ['Closed', 'Partially open', 'Open'];

const dischargeOptions = [
  'None',
  'Light',
  'Creamy',
  'Watery',
  'Sticky',
  'Unusual',
];

// ── Redesign logging catalogue ──────────────────────────────────────────────
// Mirrors redesign/logging-catalog.json: exact labels, spellings and order.
// The lists above keep their original meaning (the options the current log
// screen offers); the lists below are the full catalogue, existing options
// first. Stored values are always these labels.

/// `symptomsBody`: aches and body signals. Stored in `DailyLog.symptoms`.
const bodySymptomOptions = [
  'Cramps',
  'Headache',
  'Back pain',
  'Tender breasts',
  'Dizziness',
  'Pelvic discomfort',
  'Migraine',
  'Joint pain',
  'Muscle pain',
  'Lower back tension',
  'Pelvic pressure',
  'Weight gain',
  'Body aches',
  'Breast sensitivity',
  'Neck pain',
  'Shoulder pain',
  'Ovulation pain',
  'Bleeding',
  'Breast texture changes',
  'Vaginal dryness',
  'Vaginal irritation',
];

/// `symptomsDigestion`: digestion and appetite. Stored in `DailyLog.symptoms`.
const digestionSymptomOptions = [
  'Bloating',
  'Nausea',
  'Cravings',
  'Digestive changes',
  'Constipation',
  'Diarrhea',
  'Appetite changes',
  'Heartburn',
  'Flatulence',
  'Hunger',
  'Stomach pain',
];

/// `symptomsSkin`: skin and changes. Stored in `DailyLog.symptoms`.
const skinSymptomOptions = [
  'Acne',
  'Spotting',
  'Oily skin',
  'Dry skin',
  'Skin sensitivity',
  'Hair changes',
  'Clear skin',
  'Itchiness',
  'Skin rash',
];

/// `symptomsRest`: rest, energy and temperature. Stored in `DailyLog.symptoms`.
const restSymptomOptions = [
  'Fatigue',
  'Sleep changes',
  'Hot flashes',
  'Night sweats',
  'Insomnia',
  'Low energy',
  'Brain fog',
  'Chills',
  'Feeling warm',
  'Fever',
  'Poor sleep',
  'Sickness',
];

/// Every built-in catalogue symptom (53), in catalogue group order. Includes
/// all 16 [symptomOptions]. Anything else in `DailyLog.symptoms` is a custom
/// tag or a legacy alias and stays readable as stored.
const catalogueSymptomOptions = [
  ...bodySymptomOptions,
  ...digestionSymptomOptions,
  ...skinSymptomOptions,
  ...restSymptomOptions,
];

/// `mood`: all 54 catalogue moods in catalogue order. The first ten are the
/// existing [moodOptions], in the redesign's display order. Single select.
const catalogueMoodOptions = [
  'Happy',
  'Calm',
  'Energetic',
  'Sensitive',
  'Sad',
  'Anxious',
  'Irritable',
  'Emotional',
  'Focused',
  'Stressed',
  'Tired',
  'Mood swings',
  'Confident',
  'Confusion',
  'Tension',
  'Sleepy',
  'Exhausted',
  'Normal',
  'Depressed',
  'Surprised',
  'Worried',
  'Stunned',
  'Accomplished',
  'Smug',
  'Indifferent',
  'Sexy',
  'Assertive',
  'Impatient',
  'Pensive',
  'Weird',
  'Excited',
  'Hopeful',
  'Horny',
  'In love',
  'Peaceful',
  'Playful',
  'Proud',
  'Relaxed',
  'Satisfied',
  'Silly',
  'Hyped',
  'Jealous',
  'Frustrated',
  'Angry',
  'Grumpy',
  'Cranky',
  'Disappointed',
  'Tormented',
  'Insecure',
  'Bored',
  'Lonely',
  'Panicky',
  'Ashamed',
  'Ill',
];

/// `discharge`: the existing [dischargeOptions] plus Egg-white, With blood and
/// Green. 'None' is an explicit observation.
const catalogueDischargeOptions = [
  ...dischargeOptions,
  'Egg-white',
  'With blood',
  'Green',
];

/// `medicineTaken` choice labels: 'Taken' = true, 'Not taken' = false.
const medicineTakenOptions = ['Taken', 'Not taken'];

/// Labels written by other apps, older builds or the reference capture that
/// mean an existing catalogue option, keyed by catalogue field id.
///
/// Used only to recognise a stored value; stored values are never rewritten,
/// so 'Tense' is still read and shown as 'Tense'.
const catalogueAliases = <String, Map<String, String>>{
  'flow': {'Heavy flow': 'Heavy'},
  'mood': {
    'Anxiety': 'Anxious',
    'Irritability': 'Irritable',
    'Moodiness': 'Mood swings',
    'Stress': 'Stressed',
    'Tense': 'Tension',
  },
  'symptoms': {
    'Abdominal cramps': 'Cramps',
    'Backache': 'Back pain',
    'Breast tenderness': 'Tender breasts',
    'Reflux': 'Heartburn',
    'Hard to focus': 'Brain fog',
    'Hectic fever': 'Fever',
  },
  'appetite': {'Low appetite': 'Less than usual'},
  'libido': {
    'Increased libido': 'High',
    'Decreased libido': 'Low',
    'Neutral libido': 'Usual',
  },
  'discharge': {'No discharge': 'None', 'Egg white': 'Egg-white'},
};

/// The catalogue option [value] stands for in [field], following
/// [catalogueAliases]; [value] itself when it is not an alias (including
/// custom tags). For matching and grouping only, never for storage.
String canonicalOption(String field, String value) =>
    catalogueAliases[field]?[value] ?? value;

// ── Planned catalogue fields (DailyLog schema 2) ────────────────────────────
// Stored values are these labels, in catalogue order.

/// `painLocation` (multi select).
const painLocationOptions = [
  'Lower belly',
  'Lower back',
  'Head',
  'Breasts',
  'Joints',
  'Other',
];

/// `sleepQuality` (single select).
const sleepQualityOptions = [
  'Restful',
  'Light sleep',
  'Restless',
  'Interrupted',
];

/// `energy` (single select).
const energyOptions = ['Low', 'Steady', 'High'];

/// `exerciseType` (multi select).
const exerciseTypeOptions = [
  'Walking',
  'Running',
  'Yoga',
  'Swimming',
  'Cycling',
  'Strength',
  'Pilates',
  'Dancing',
  'HIIT',
  'Other',
];

/// `appetite` (single select).
const appetiteOptions = [
  'Less than usual',
  'As usual',
  'More than usual',
  'Cravings',
];

/// `intimacy` (single select, private). 'None' is an explicit observation;
/// 'Prefer not to say' is a recorded non-answer.
const intimacyOptions = [
  'None',
  'Partnered',
  'Solo',
  'Prefer not to say',
  'Kissing',
];

/// `protection` (single select, private). 'Not sure' is unknown, not none.
const protectionOptions = [
  'Condom',
  'Regular method',
  'Other',
  'None',
  'Not sure',
];

/// `libido` (single select, private).
const libidoOptions = ['Low', 'Usual', 'High', 'Not sure'];

/// `pregnancyTest` and `ovulationTest` (single select, private). Recorded as
/// shown on the test and never interpreted. 'Not taken' means no test was
/// taken, which is different from not logged.
const testResultOptions = ['Positive', 'Negative', 'Unclear', 'Not taken'];

/// `careActions` (multi select).
const careActionOptions = [
  'Heat pad',
  'Rest',
  'Stretching',
  'Breathing',
  'A little walk',
  'Other',
];

/// Optional observation context; absence is never interpreted as normal.
const painInterferenceOptions = <String>[
  'No interference',
  'Some activities harder',
  'Unable to do usual activities',
  'Not sure',
];

const temperatureContextOptions = <String>[
  'Usual conditions',
  'Disrupted sleep',
  'Illness or fever',
  'Different measurement time',
  'Alcohol',
  'Other disturbance',
];
