import 'dart:io';

import 'ai_provider.dart';
import 'family_brain_ai_schema.dart';
import 'family_brain_context.dart';
import 'local_fallback_adapter.dart';

/// Family Brain intelligence layer: provider → schema → validation.
///
/// Does not write the database or touch UI. The Action Engine does that.
class FamilyBrainAiService {
  const FamilyBrainAiService({
    this.provider,
    this.fallback = const LocalFallbackAdapter(),
  });

  final AiProvider? provider;
  final AiProvider fallback;

  Future<FamilyBrainAiResponse> interpret({
    required FamilyBrainInput input,
    required FamilyBrainContext context,
  }) async {
    final result = await understandResult(input: input, context: context);
    return result.response;
  }

  Future<FamilyBrainUnderstand> understandResult({
    required FamilyBrainInput input,
    required FamilyBrainContext context,
  }) async {
    if (provider != null) {
      try {
        final cloud = FamilyBrainAiValidator.resolve(
          await provider!.interpret(input: input, context: context),
          context: context,
          originalText: input.text,
        );
        if (cloud.hasCreateActions) {
          return FamilyBrainUnderstand(
            response: cloud,
            usedCloud: provider!.id != fallback.id,
            usedFallback: false,
          );
        }
      } on SocketException {
        return FamilyBrainUnderstand(
          response: await _fallback(input, context),
          usedCloud: false,
          usedFallback: true,
          error: 'offline',
        );
      } catch (_) {
        return FamilyBrainUnderstand(
          response: await _fallback(input, context),
          usedCloud: false,
          usedFallback: true,
          error: 'ai_failed',
        );
      }
    }

    return FamilyBrainUnderstand(
      response: await _fallback(input, context),
      usedCloud: false,
      usedFallback: false,
    );
  }

  Future<FamilyBrainAiResponse> _fallback(
    FamilyBrainInput input,
    FamilyBrainContext context,
  ) async {
    return FamilyBrainAiValidator.resolve(
      await fallback.interpret(input: input, context: context),
      context: context,
      originalText: input.text,
    );
  }
}

class FamilyBrainUnderstand {
  const FamilyBrainUnderstand({
    required this.response,
    this.usedCloud = false,
    this.usedFallback = false,
    this.error,
  });

  final FamilyBrainAiResponse response;
  final bool usedCloud;
  final bool usedFallback;
  final String? error;
}
