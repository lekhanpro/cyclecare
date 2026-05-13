import 'package:flutter/material.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/soft_card.dart';

// ─── Seed content ─────────────────────────────────────────────────────────────
class Article {
  const Article({
    required this.id,
    required this.title,
    required this.category,
    required this.emoji,
    required this.summary,
    required this.body,
  });

  final String id;
  final String title;
  final String category;
  final String emoji;
  final String summary;
  final String body;
}

const _articles = [
  Article(
    id: 'cycle_basics',
    title: 'Understanding Your Cycle',
    category: 'Basics',
    emoji: '🌸',
    summary: 'Learn about the four phases of the menstrual cycle.',
    body: '''
The menstrual cycle has four phases:

**Menstrual phase (Days 1–5)**
Your period. The uterine lining sheds. Estrogen and progesterone are at their lowest.

**Follicular phase (Days 1–13)**
Overlaps with menstruation. FSH stimulates follicle growth. Estrogen rises, rebuilding the uterine lining.

**Ovulation (Day 14 approx.)**
A surge in LH triggers the release of an egg. This is your most fertile time.

**Luteal phase (Days 15–28)**
The empty follicle becomes the corpus luteum, producing progesterone. If no pregnancy occurs, levels drop and your period begins.

Cycle length varies from 21–35 days. Tracking helps you understand your personal pattern.
''',
  ),
  Article(
    id: 'fertile_window',
    title: 'Fertile Window Explained',
    category: 'Fertility',
    emoji: '🌿',
    summary: 'When are you most likely to conceive?',
    body: '''
The fertile window is the period when pregnancy is possible. Sperm can survive up to 5 days, and an egg lives 12–24 hours after ovulation.

**Your fertile window is approximately:**
- 5 days before ovulation
- The day of ovulation
- 1 day after ovulation

**Signs of ovulation:**
- Egg-white cervical mucus
- Slight rise in basal body temperature (BBT)
- Mild pelvic pain (mittelschmerz)
- LH surge on ovulation test strips

CycleCare estimates your fertile window based on your cycle history. The more cycles you log, the more accurate the prediction.
''',
  ),
  Article(
    id: 'pms_vs_pmdd',
    title: 'PMS vs PMDD',
    category: 'Wellness',
    emoji: '💜',
    summary: 'What\'s the difference and how to manage symptoms.',
    body: '''
**PMS (Premenstrual Syndrome)**
Affects up to 75% of people who menstruate. Symptoms include bloating, mood changes, breast tenderness, and fatigue in the week before your period.

**PMDD (Premenstrual Dysphoric Disorder)**
A more severe form affecting 3–8% of people. Symptoms significantly impact daily functioning and include severe depression, anxiety, irritability, and physical symptoms.

**Management strategies:**
- Regular exercise
- Reducing caffeine and alcohol
- Adequate sleep
- Stress management
- Tracking symptoms to identify patterns

If symptoms significantly affect your quality of life, speak with a healthcare provider. Effective treatments exist.
''',
  ),
  Article(
    id: 'bbt_tracking',
    title: 'Basal Body Temperature',
    category: 'Fertility',
    emoji: '🌡️',
    summary: 'How to track BBT and what it tells you.',
    body: '''
Basal body temperature (BBT) is your lowest resting temperature, measured first thing in the morning before getting up.

**After ovulation**, progesterone causes a slight rise of 0.2–0.5°C (0.4–1°F) that persists until your next period.

**How to track:**
1. Use a basal thermometer (reads to 0.1°)
2. Take your temperature at the same time every morning
3. Record it in CycleCare before getting out of bed
4. Look for the sustained rise to confirm ovulation occurred

**Important:** BBT confirms ovulation has already happened — it doesn\'t predict it in advance. Combine with cervical mucus observation for better fertility awareness.
''',
  ),
  Article(
    id: 'nutrition_cycle',
    title: 'Eating With Your Cycle',
    category: 'Wellness',
    emoji: '🥗',
    summary: 'How nutrition needs change throughout your cycle.',
    body: '''
Your nutritional needs shift with your hormones throughout the month.

**Menstrual phase:** Iron-rich foods (leafy greens, legumes, red meat) to replenish what\'s lost. Magnesium helps with cramps.

**Follicular phase:** Light, energizing foods. Fermented foods support estrogen metabolism.

**Ovulation:** Antioxidant-rich foods support egg quality. Zinc supports hormone production.

**Luteal phase:** Complex carbohydrates help stabilize mood. Calcium and vitamin B6 may reduce PMS symptoms. Reduce salt to minimize bloating.

These are general guidelines. Individual needs vary. Consult a registered dietitian for personalized advice.
''',
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  String _selectedCategory = 'All';
  final _bookmarks = <String>{};

  List<String> get _categories => [
        'All',
        ..._articles.map((a) => a.category).toSet().toList()..sort(),
      ];

  List<Article> get _filtered => _selectedCategory == 'All'
      ? _articles
      : _articles.where((a) => a.category == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Education'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_rounded),
            onPressed: () => _showBookmarks(),
            tooltip: 'Bookmarks',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final article = _filtered[i];
                return _ArticleCard(
                  article: article,
                  bookmarked: _bookmarks.contains(article.id),
                  onBookmark: () => setState(() {
                    if (_bookmarks.contains(article.id)) {
                      _bookmarks.remove(article.id);
                    } else {
                      _bookmarks.add(article.id);
                    }
                  }),
                  onTap: () => _openArticle(article),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openArticle(Article article) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ArticleDetailScreen(article: article),
      ),
    );
  }

  void _showBookmarks() {
    final bookmarked =
        _articles.where((a) => _bookmarks.contains(a.id)).toList();
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bookmarks',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 12),
            if (bookmarked.isEmpty)
              Text('No bookmarks yet.',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ))
            else
              ...bookmarked.map((a) => ListTile(
                    leading:
                        Text(a.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(a.title),
                    onTap: () {
                      Navigator.pop(context);
                      _openArticle(a);
                    },
                  )),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
    required this.bookmarked,
    required this.onBookmark,
    required this.onTap,
  });

  final Article article;
  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          Text(article.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article.category,
                        style: AppTextStyles.textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(article.title,
                    style: AppTextStyles.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
                Text(article.summary,
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    )),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: bookmarked
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.muted,
            ),
            onPressed: onBookmark,
          ),
        ],
      ),
    );
  }
}

class _ArticleDetailScreen extends StatelessWidget {
  const _ArticleDetailScreen({required this.article});
  final Article article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(article.emoji, style: const TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 16),
            Text(article.title,
                style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 8),
            Text(article.summary,
                style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                )),
            const Divider(height: 32),
            // Render markdown-lite body
            ..._renderBody(article.body, context),
            const SizedBox(height: 32),
            SoftCard(
              child: Text(
                '⚕️ This article is for educational purposes only and does not constitute medical advice.',
                style: AppTextStyles.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _renderBody(String body, BuildContext context) {
    final lines = body.trim().split('\n');
    final widgets = <Widget>[];
    for (final line in lines) {
      if (line.startsWith('**') && line.endsWith('**')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            line.replaceAll('**', ''),
            style: AppTextStyles.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontWeight: FontWeight.w700)),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ));
      } else if (line.trim().isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ));
      }
    }
    return widgets;
  }
}
