import '../../../domain/models/app_user.dart';
import '../family_brain_parser.dart';
import 'ai_provider.dart';
import 'family_brain_ai_schema.dart';
import 'family_brain_context.dart';

/// On-device parser exposed through the same [AiProvider] interface.
class LocalFallbackAdapter implements AiProvider {
  const LocalFallbackAdapter();

  @override
  String get id => 'local_fallback';

  @override
  Future<FamilyBrainAiResponse> interpret({
    required FamilyBrainInput input,
    required FamilyBrainContext context,
  }) async {
    final drafts = FamilyBrainParser.parseAll(
      input.text,
      now: context.now,
      members: [
        for (final member in context.members)
          AppUser(
            id: member.id,
            name: member.name,
            phone: '',
            language: context.language,
            createdAt: context.now,
          ),
      ],
      currentUser: context.currentUser == null
          ? null
          : AppUser(
              id: context.currentUser!.id,
              name: context.currentUser!.name,
              phone: '',
              language: context.language,
              createdAt: context.now,
            ),
      imagePath: input.imagePath,
    );
    return FamilyBrainAiResponse.fromDrafts(
      drafts,
      providerId: id,
      sourceText: input.text,
    );
  }
}
