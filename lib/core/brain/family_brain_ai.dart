import 'package:http/http.dart' as http;

import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';
import '../config/app_config.dart';
import 'ai/ai_provider.dart';
import 'ai/family_brain_ai_schema.dart';
import 'ai/family_brain_ai_service.dart';
import 'ai/family_brain_context.dart';
import 'ai/gemini_ai_adapter.dart';
import 'ai/local_fallback_adapter.dart';
import 'brain_session.dart';
import 'family_brain_parser.dart';

class BrainUnderstandResult {
  const BrainUnderstandResult({
    required this.drafts,
    required this.originalText,
    this.usedCloud = false,
    this.usedFallback = false,
    this.clarification,
    this.error,
  });

  final List<BrainDraft> drafts;
  final String originalText;
  final bool usedCloud;
  final bool usedFallback;
  final String? clarification;
  final String? error;

  bool get isOk => drafts.isNotEmpty;
}

/// App-facing Family Brain AI entry. Provider-specific code lives in adapters.
///
/// App → [FamilyBrainAiService] → [AiProvider] (Gemini today) → schema
/// → validation → drafts for confirmation → Action Engine → app data.
///
/// Secrets stay on the server. Falls back to the on-device parser.
class FamilyBrainAi {
  static FamilyBrainAiService service({
    http.Client? client,
    Duration timeout = const Duration(seconds: 12),
    String? backendUrl,
  }) {
    final url = _origin(backendUrl ?? AppConfig.aiBackendUrl);
    return FamilyBrainAiService(
      provider: url.isEmpty
          ? null
          : GeminiAiAdapter(origin: url, client: client, timeout: timeout),
      fallback: const LocalFallbackAdapter(),
    );
  }

  static Future<BrainUnderstandResult> understand({
    required String text,
    required DateTime now,
    List<AppUser> members = const [],
    List<TaskItem> items = const [],
    String? imagePath,
    String? imageBase64,
    String? mimeType,
    String language = 'en',
    http.Client? client,
    Duration timeout = const Duration(seconds: 12),
    String? backendUrl,
  }) async {
    final compactItems = items
        .where((item) => item.isOpen)
        .take(12)
        .toList();
    final understood = await service(
      client: client,
      timeout: timeout,
      backendUrl: backendUrl,
    ).understandResult(
      input: FamilyBrainInput(
        text: text,
        imageBase64: imageBase64,
        mimeType: mimeType,
        imagePath: imagePath,
      ),
      context: FamilyBrainContext.fromApp(
        now: now,
        language: language,
        members: members,
        items: compactItems,
        recentUserTexts: BrainSession.recentForProvider(),
        lastEvent: BrainSession.lastEvent,
      ),
    );
    final drafts = understood.response.toDrafts(originalText: text, now: now);
    BrainSession.remember(text: text, drafts: drafts);
    return BrainUnderstandResult(
      drafts: drafts,
      originalText: text,
      usedCloud: understood.usedCloud,
      usedFallback: understood.usedFallback,
      clarification: understood.response.clarification,
      error: understood.error,
    );
  }

  static String _origin(String url) => url.trim().replaceAll(RegExp(r'/+$'), '');

  /// Compatibility mapper: gateway/Gemini JSON → confirmation drafts.
  static List<BrainDraft> draftsFromAiJson(
    Map<dynamic, dynamic> json, {
    required String originalText,
    required DateTime now,
    List<AppUser> members = const [],
  }) {
    final resolved = FamilyBrainAiValidator.resolve(
      GeminiAiAdapter.mapGatewayPayload(json, sourceText: originalText),
      context: FamilyBrainContext.fromApp(now: now, members: members),
      originalText: originalText,
    );
    return resolved.toDrafts(originalText: originalText, now: now);
  }
}
