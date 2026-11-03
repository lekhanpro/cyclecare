import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'application/education_controller.dart';
import 'article_sources.dart';
import 'domain/article.dart';
import 'domain/article_block.dart';
import 'domain/core_articles.dart';
export 'domain/article.dart';

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

final kArticles = kCoreArticles;

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
      MaterialPageRoute<void>(builder: (_) => ArticleReaderScreen(article: article)),
    );
  }

  void _toggleBookmark(Article article) {
    final added = ref
        .read(educationBookmarksProvider.notifier)
        .toggle(article.id);
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
    final filtered =
        _query.trim().isNotEmpty || _category != null || _savedOnly;

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
                  icon: AppIcons.library,
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                for (final category in ArticleCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SelectableChip(
                      label: category.label,
                      icon: category.icon,
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
                  label: bookmarks.isEmpty
                      ? 'Saved'
                      : 'Saved ${bookmarks.length}',
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
                    icon: _savedOnly && bookmarks.isEmpty
                        ? Icons.bookmark_border_rounded
                        : Icons.search_rounded,
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
                      final position = _disclaimerDismissed ? index : index - 1;
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
          count == total ? '$total articles' : '$count of $total articles',
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
            child: Icon(
              article.icon,
              size: 22,
              color: article.category.tone(context),
            ),
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
            bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
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

class ArticleReaderScreen extends ConsumerStatefulWidget {
  const ArticleReaderScreen({super.key, required this.article});

  final Article article;

  @override
  ConsumerState<ArticleReaderScreen> createState() => ArticleReaderScreenState();
}

class ArticleReaderScreenState extends ConsumerState<ArticleReaderScreen> {
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
    final added = ref
        .read(educationBookmarksProvider.notifier)
        .toggle(widget.article.id);
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
    final article = widget.article;
    final tone = article.category.tone(context);
    final bookmarked = ref
        .watch(educationBookmarksProvider)
        .contains(article.id);

    final related = kArticles
        .where(
          (other) =>
              other.category == article.category && other.id != article.id,
        )
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
              child: Icon(
                article.icon,
                size: 32,
                color: article.category.tone(context),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Reveal(
            index: 1,
            child: Text(
              article.title,
              style: AppTextStyles.heading(
                fontSize: 30,
              ).copyWith(color: context.inkColor),
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
          const SizedBox(height: 10),
          Text('Article available offline. Source links open online.',
            style: AppTextStyles.body(fontSize: 12, height: 1.5)
                .copyWith(color: context.mutedColor)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: context.lineColor),
          ),
          Reveal(
            index: 3,
            child: _ArticleBody(blocks: article.blocks, tone: tone),
          ),
          if (kArticleSources[article.id] case final sources?) ...[
            const SizedBox(height: 28),
            _SourcesSection(sources: sources, tone: tone),
          ],
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
                  icon: other.icon,
                  title: other.title,
                  subtitle: '${other.readMinutes} min read',
                  accent: tone,
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => ArticleReaderScreen(article: other),
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

/// Typed offline content; callouts and lists remain distinct semantic blocks.
class _ArticleBody extends StatelessWidget {
  const _ArticleBody({required this.blocks, required this.tone});
  final List<ArticleBlock> blocks;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.body(
      fontSize: 15,
      height: 1.65,
    ).copyWith(color: context.inkColor);
    Widget rich(String text) => Text.rich(
      TextSpan(
        children: [
          for (final span in parseInlineSpans(text))
            TextSpan(
              text: span.text,
              style: base.copyWith(
                fontWeight: span.emphasis ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in blocks)
          Padding(
            padding: EdgeInsets.only(
              bottom: block is ArticleHeading ? 8 : 16,
              top: block is ArticleHeading ? 12 : 0,
            ),
            child: switch (block) {
              ArticleHeading(:final text) => Semantics(
                header: true,
                child: Text(
                  text,
                  style: AppTextStyles.heading(
                    fontSize: 21,
                  ).copyWith(color: context.inkColor),
                ),
              ),
              ArticleParagraph(:final text) => rich(text),
              ArticleList(:final items) => Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5, right: 10),
                            child: Text('•', style: base.copyWith(color: tone)),
                          ),
                          Expanded(child: rich(item)),
                        ],
                      ),
                    ),
                ],
              ),
              ArticleCallout(:final text, :final kind) => AppCard(
                color: tone.withOpacity(0.10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(switch (kind) {
                      ArticleCalloutKind.note => 'Note',
                      ArticleCalloutKind.caution => 'Worth knowing',
                      ArticleCalloutKind.pullQuote => 'Remember',
                    }, style: base.copyWith(fontWeight: FontWeight.w700)),
                    rich(text),
                  ],
                ),
              ),
              ArticleSourceList(:final sources) => _SourcesSection(
                sources: sources,
                tone: tone,
              ),
            },
          ),
      ],
    );
  }
}

// ─── Sources ─────────────────────────────────────────────────────────────────

class _SourcesSection extends StatelessWidget {
  const _SourcesSection({required this.sources, required this.tone});

  final List<ArticleSource> sources;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sources',
          style: text.titleMedium?.copyWith(
            color: context.inkColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Where this article comes from. Opens in your browser.',
          style: text.bodySmall?.copyWith(color: context.mutedColor),
        ),
        const SizedBox(height: 12),
        for (final s in sources)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SourceRow(source: s, tone: tone),
          ),
      ],
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source, required this.tone});

  final ArticleSource source;
  final Color tone;

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!ok && context.mounted) {
      showAppToast(
        context,
        message: 'Could not open the link. Check you are online.',
        kind: ToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final meta = [
      if (source.isPaper) 'Research paper',
      source.publisher,
      if (source.year != null) '${source.year}',
    ].join(' · ');

    return AppCard(
      emphasis: CardEmphasis.outlined,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                source.isPaper ? AppIcons.science : AppIcons.article,
                size: 18,
                color: tone,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.title,
                      style: text.bodyMedium?.copyWith(
                        color: context.inkColor,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: text.labelSmall?.copyWith(
                        color: context.mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => _open(context, source.url),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(source.isPaper ? 'Read online' : 'Open page'),
              ),
              if (source.pdfUrl != null)
                TextButton.icon(
                  onPressed: () => _open(context, source.pdfUrl!),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text('Open PDF'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
