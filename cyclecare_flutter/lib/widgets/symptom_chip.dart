import 'package:flutter/material.dart';

import '../core/theme/cyclecare_theme.dart';

class SymptomChip extends StatelessWidget {
  const SymptomChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      checkmarkColor: CycleCareColors.rose,
      selectedColor: CycleCareColors.predicted,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? CycleCareColors.rose.withOpacity(0.45) : CycleCareColors.line,
      ),
    );
  }
}
