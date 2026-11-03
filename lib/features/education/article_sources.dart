// ─────────────────────────────────────────────────────────────────────────────
// Article sources
//
// Every link here was checked before it was added; the log of what each URL
// returned is kept with the build notes (sources_verified.txt). Rules:
//
//  • `url` must have answered 200 with a real page.
//  • Paper titles, journals and years come from NCBI's own E-utilities
//    records, not from memory.
//  • `pdfUrl` is only ever the address the paper's own page declares in its
//    `citation_pdf_url` metadata — never built by hand. PubMed Central serves
//    those PDFs behind a browser check, so they open in a real browser but
//    cannot be fetched by a script; that is why they are not stated as
//    script-verified.
//  • NHS and WHO pages carry no single publication year, so none is given
//    rather than an invented one.
// ─────────────────────────────────────────────────────────────────────────────

class ArticleSource {
  const ArticleSource({
    required this.title,
    required this.publisher,
    required this.url,
    this.year,
    this.pdfUrl,
  });

  final String title;

  /// Journal for a paper, organisation for a guidance page.
  final String publisher;
  final int? year;
  final String url;
  final String? pdfUrl;

  /// A peer-reviewed paper, as opposed to patient guidance.
  bool get isPaper => url.contains('pmc.ncbi.nlm.nih.gov');
}

// ── Guidance pages ───────────────────────────────────────────────────────────

const _nhsPeriods = ArticleSource(
  title: 'Periods',
  publisher: 'NHS',
  url: 'https://www.nhs.uk/conditions/periods/',
);
const _nhsIrregular = ArticleSource(
  title: 'Irregular periods',
  publisher: 'NHS',
  url: 'https://www.nhs.uk/conditions/irregular-periods/',
);
const _nhsHeavy = ArticleSource(
  title: 'Heavy periods',
  publisher: 'NHS',
  url: 'https://www.nhs.uk/conditions/heavy-periods/',
);
const _nhsPain = ArticleSource(
  title: 'Period pain',
  publisher: 'NHS',
  url: 'https://www.nhs.uk/conditions/period-pain/',
);
const _nhsPms = ArticleSource(
  title: 'PMS (premenstrual syndrome)',
  publisher: 'NHS',
  url: 'https://www.nhs.uk/conditions/pre-menstrual-syndrome/',
);
const _nhsPcos = ArticleSource(
  title: 'Polycystic ovary syndrome',
  publisher: 'NHS',
  url: 'https://www.nhs.uk/conditions/polycystic-ovary-syndrome-pcos/',
);
const _nhsEndo = ArticleSource(
  title: 'Endometriosis',
  publisher: 'NHS',
  url: 'https://www.nhs.uk/conditions/endometriosis/',
);
const _nhsMenopause = ArticleSource(
  title: 'Menopause',
  publisher: 'NHS',
  url: 'https://www.nhs.uk/conditions/menopause/',
);
const _nhsIron = ArticleSource(
  title: 'Iron deficiency anaemia',
  publisher: 'NHS',
  url: 'https://www.nhs.uk/conditions/iron-deficiency-anaemia/',
);
const _nhsContraception = ArticleSource(
  title: 'Your contraception guide',
  publisher: 'NHS',
  url: 'https://www.nhs.uk/contraception/',
);
const _nhsNfp = ArticleSource(
  title: 'Natural family planning (fertility awareness)',
  publisher: 'NHS',
  url: 'https://www.nhs.uk/contraception/methods-of-contraception/'
      'natural-family-planning/',
);
const _nhsExercise = ArticleSource(
  title: 'Exercise',
  publisher: 'NHS',
  url: 'https://www.nhs.uk/live-well/exercise/',
);
const _nhsEatWell = ArticleSource(
  title: 'Eat well',
  publisher: 'NHS',
  url: 'https://www.nhs.uk/live-well/eat-well/',
);
const _whoEndo = ArticleSource(
  title: 'Endometriosis — fact sheet',
  publisher: 'World Health Organization',
  url: 'https://www.who.int/news-room/fact-sheets/detail/endometriosis',
);
const _whoPcos = ArticleSource(
  title: 'Polycystic ovary syndrome — fact sheet',
  publisher: 'World Health Organization',
  url: 'https://www.who.int/news-room/fact-sheets/detail/'
      'polycystic-ovary-syndrome',
);
const _whoContraception = ArticleSource(
  title: 'Family planning/contraception methods — fact sheet',
  publisher: 'World Health Organization',
  url: 'https://www.who.int/news-room/fact-sheets/detail/'
      'family-planning-contraception',
);
const _acogHeavy = ArticleSource(
  title: 'Heavy menstrual bleeding',
  publisher: 'ACOG',
  url: 'https://www.acog.org/womens-health/faqs/heavy-menstrual-bleeding',
);
const _acogPms = ArticleSource(
  title: 'Premenstrual syndrome (PMS)',
  publisher: 'ACOG',
  url: 'https://www.acog.org/womens-health/faqs/premenstrual-syndrome',
);

// ── Research papers (open access, PubMed Central) ────────────────────────────

const _paperRealWorldCycles = ArticleSource(
  title: 'Real-world menstrual cycle characteristics of more than 600,000 '
      'menstrual cycles',
  publisher: 'npj Digital Medicine',
  year: 2019,
  url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC6710244/',
  pdfUrl: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC6710244/pdf/'
      '41746_2019_Article_152.pdf',
);
const _paperPcosGuideline = ArticleSource(
  title: 'Recommendations from the 2023 International Evidence-based '
      'Guideline for the Assessment and Management of Polycystic Ovary '
      'Syndrome',
  publisher: 'The Journal of Clinical Endocrinology & Metabolism',
  year: 2023,
  url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC10505534/',
);
const _paperEndoDiagnosis = ArticleSource(
  title: 'Time to Diagnose Endometriosis: Current Status, Challenges and '
      'Regional Characteristics — A Systematic Literature Review',
  publisher: 'BJOG',
  year: 2025,
  url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC11625652/',
);
const _paperPmsRhythms = ArticleSource(
  title: 'Biological rhythms in premenstrual syndrome and premenstrual '
      'dysphoric disorder: a systematic review',
  publisher: "BMC Women's Health",
  year: 2024,
  url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC11457342/',
);
const _paperIronHmb = ArticleSource(
  title: 'A Review of Clinical Guidelines on the Management of Iron '
      'Deficiency and Iron-Deficiency Anemia in Women with Heavy Menstrual '
      'Bleeding',
  publisher: 'Advances in Therapy',
  year: 2021,
  url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC7695235/',
  pdfUrl: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC7695235/pdf/'
      '12325_2020_Article_1564.pdf',
);
const _paperSleep = ArticleSource(
  title: 'The Menstrual Cycle and Sleep',
  publisher: 'Sleep Medicine Clinics',
  year: 2023,
  url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC11562818/',
  pdfUrl: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC11562818/pdf/'
      'nihms-2004993.pdf',
);

/// Sources by article id. An article with no verified source has no entry;
/// one was never attached just to fill the list.
const kArticleSources = <String, List<ArticleSource>>{
  'cycle-phases': [_nhsPeriods, _paperRealWorldCycles],
  'cycle-length': [_nhsPeriods, _nhsIrregular, _paperRealWorldCycles],
  'reading-flow': [_nhsHeavy, _acogHeavy],
  'hormones-101': [_nhsPeriods],
  'fertile-window': [_nhsNfp],
  'bbt': [_nhsNfp],
  'cervical-mucus': [_nhsNfp],
  'lh-tests': [_nhsNfp],
  'cramps': [_nhsPain],
  'pms-pmdd': [_nhsPms, _acogPms, _paperPmsRhythms],
  'eating-with-cycle': [_nhsEatWell],
  'iron-energy': [_nhsIron, _paperIronHmb],
  'bloating-fluid': [_nhsPms],
  'pcos': [_nhsPcos, _whoPcos, _paperPcosGuideline],
  'endometriosis': [_nhsEndo, _whoEndo, _paperEndoDiagnosis],
  'sleep-cycle': [_paperSleep],
  'movement-cycle': [_nhsExercise],
  'stress-late': [_nhsIrregular],
  // New articles.
  'heavy-periods': [_nhsHeavy, _acogHeavy, _paperIronHmb],
  'irregular-periods': [_nhsIrregular, _paperRealWorldCycles],
  'perimenopause': [_nhsMenopause],
  'contraception-basics': [_nhsContraception, _whoContraception],
  'fertility-awareness': [_nhsNfp, _whoContraception],
  'real-world-cycles': [_paperRealWorldCycles, _nhsPeriods],
};
