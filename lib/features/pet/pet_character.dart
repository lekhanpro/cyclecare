import 'package:flutter/material.dart';
import 'pet_care.dart';
import 'pet_companion.dart';
import 'pet_models.dart';

/// Original clay artwork, shared by legacy character call sites.
class PetCharacter extends StatelessWidget {
  const PetCharacter({
    super.key,
    required this.type,
    required this.mood,
    required this.stage,
    required this.size,
    this.onTap,
    this.semanticLabel,
  });
  final PetType type;
  final PetMood mood;
  final PetStage stage;
  final double size;
  final VoidCallback? onTap;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel ?? '${type.name}, ${stage.label}, ${mood.name}',
    child: PetCompanion(
      type: type,
      name: type.name,
      width: size,
      showControls: false,
      showHint: false,
      onGreeting: onTap,
    ),
  );
}
