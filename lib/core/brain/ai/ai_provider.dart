import 'family_brain_ai_schema.dart';
import 'family_brain_context.dart';

/// User input the provider should interpret. No application models.
class FamilyBrainInput {
  const FamilyBrainInput({
    required this.text,
    this.imageBase64,
    this.mimeType,
    this.imagePath,
  });

  final String text;
  final String? imageBase64;
  final String? mimeType;
  final String? imagePath;
}

/// Replaceable AI provider. Family Brain never calls Gemini APIs directly.
///
/// A new provider implements this interface and returns [FamilyBrainAiResponse].
/// Task/event/reminder models, the Action Engine, UI, local parser, and
/// persistence stay unchanged.
abstract class AiProvider {
  String get id;

  Future<FamilyBrainAiResponse> interpret({
    required FamilyBrainInput input,
    required FamilyBrainContext context,
  });
}
