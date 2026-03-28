import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = ref.watch(darkModeProvider);
    final currentColor = ref.watch(themeColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dark mode
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark color scheme'),
            secondary: const Icon(Icons.dark_mode),
            value: isDark,
            onChanged: (v) => ref.read(darkModeProvider.notifier).state = v,
          ),
          const Divider(),
          const SizedBox(height: 16),

          Text('Color Palette', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          // Color palette grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: AppConstants.themePalettes.length,
            itemBuilder: (_, i) {
              final entry = AppConstants.themePalettes.entries.elementAt(i);
              final isSelected = currentColor == entry.value;
              return GestureDetector(
                onTap: () => ref.read(themeColorProvider.notifier).state = entry.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(entry.value),
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: isSelected ? [BoxShadow(color: Color(entry.value).withOpacity(0.5), blurRadius: 8)] : null,
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Palette names
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: AppConstants.themePalettes.entries.map((e) =>
              Chip(
                label: Text(e.key, style: const TextStyle(fontSize: 11)),
                backgroundColor: currentColor == e.value ? Color(e.value).withOpacity(0.2) : null,
                side: currentColor == e.value ? BorderSide(color: Color(e.value)) : BorderSide.none,
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }
}
