import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EducationScreen extends ConsumerStatefulWidget {
  const EducationScreen({super.key});
  @override
  ConsumerState<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<EducationScreen> {
  String _selectedCategory = 'All';
  final Set<String> _bookmarked = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _categories = ['All', 'Menstrual Health', 'Fertility', 'Pregnancy', 'Perimenopause', 'Mental Health'];

  static const _articles = [
    {'id': '1', 'title': 'Understanding Your Menstrual Cycle', 'category': 'Menstrual Health', 'readTime': '5 min', 'summary': 'Learn about the four phases of your menstrual cycle and what happens in each.'},
    {'id': '2', 'title': 'Period Pain: What\'s Normal?', 'category': 'Menstrual Health', 'readTime': '4 min', 'summary': 'Distinguishing between normal cramps and signs that you should see a doctor.'},
    {'id': '3', 'title': 'Tracking BBT for Fertility', 'category': 'Fertility', 'readTime': '6 min', 'summary': 'How basal body temperature tracking can help identify your fertile window.'},
    {'id': '4', 'title': 'Cervical Mucus Patterns', 'category': 'Fertility', 'readTime': '5 min', 'summary': 'Understanding changes in cervical mucus throughout your cycle.'},
    {'id': '5', 'title': 'Week by Week: First Trimester', 'category': 'Pregnancy', 'readTime': '8 min', 'summary': 'What to expect during weeks 1-12 of pregnancy.'},
    {'id': '6', 'title': 'Prenatal Nutrition Guide', 'category': 'Pregnancy', 'readTime': '7 min', 'summary': 'Essential nutrients and foods for a healthy pregnancy.'},
    {'id': '7', 'title': 'Signs of Perimenopause', 'category': 'Perimenopause', 'readTime': '6 min', 'summary': 'Common symptoms and what to expect as you approach menopause.'},
    {'id': '8', 'title': 'HRT: Pros and Cons', 'category': 'Perimenopause', 'readTime': '7 min', 'summary': 'Understanding hormone replacement therapy options.'},
    {'id': '9', 'title': 'PMS vs PMDD', 'category': 'Mental Health', 'readTime': '5 min', 'summary': 'Understanding the difference and when to seek help.'},
    {'id': '10', 'title': 'Cycle and Mood Connection', 'category': 'Mental Health', 'readTime': '4 min', 'summary': 'How hormonal changes affect your mental health throughout the cycle.'},
    {'id': '11', 'title': 'PCOS: A Comprehensive Guide', 'category': 'Menstrual Health', 'readTime': '8 min', 'summary': 'Symptoms, diagnosis, and management of Polycystic Ovary Syndrome.'},
    {'id': '12', 'title': 'Endometriosis Explained', 'category': 'Menstrual Health', 'readTime': '7 min', 'summary': 'What is endometriosis and how to manage it.'},
  ];

  List<Map<String, String>> get _filteredArticles {
    return _articles.where((a) {
      final matchCategory = _selectedCategory == 'All' || a['category'] == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          a['title']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a['summary']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Education')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search articles...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 8),

          // Category chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Articles list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredArticles.length,
              itemBuilder: (_, i) {
                final article = _filteredArticles[i];
                final isBookmarked = _bookmarked.contains(article['id']);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(article['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(article['summary']!, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text(article['category']!, style: const TextStyle(fontSize: 10)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 2),
                            Text(article['readTime']!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? theme.colorScheme.primary : null),
                      onPressed: () {
                        setState(() {
                          isBookmarked ? _bookmarked.remove(article['id']) : _bookmarked.add(article['id']!);
                        });
                      },
                    ),
                    onTap: () => _showArticle(context, article),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showArticle(BuildContext context, Map<String, String> article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Chip(label: Text(article['category']!)),
              const SizedBox(height: 8),
              Text(article['title']!, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${article['readTime']} read', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(article['summary']!, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              Text(
                'This is a placeholder for the full article content. In the production version, '
                'articles will be stored as Markdown files in the assets/education/ directory and '
                'rendered using the flutter_markdown package.\n\n'
                'The content will cover detailed information about ${article['title']}, '
                'including evidence-based research, practical tips, and when to consult a healthcare provider.\n\n'
                'Disclaimer: This content is for educational purposes only and should not be considered '
                'medical advice. Always consult with your healthcare provider for medical decisions.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
