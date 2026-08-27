import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'ai_provider.dart';
import 'family_brain_ai_schema.dart';
import 'family_brain_context.dart';

/// Maps the existing Family Brain AI gateway (Gemini on the server) into
/// the provider-independent [FamilyBrainAiResponse] schema.
///
/// Talks only to [origin]/understand. GEMINI_API_KEY stays on the server.
class GeminiAiAdapter implements AiProvider {
  GeminiAiAdapter({
    required this.origin,
    this._client,
    this.timeout = const Duration(seconds: 12),
  });

  final String origin;
  final http.Client? _client;
  final Duration timeout;

  @override
  String get id => 'gemini';

  @override
  Future<FamilyBrainAiResponse> interpret({
    required FamilyBrainInput input,
    required FamilyBrainContext context,
  }) async {
    final httpClient = _client ?? http.Client();
    final owned = _client == null;
    try {
      final response = await httpClient
          .post(
            Uri.parse('$origin/understand'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': input.text,
              ...context.toProviderPayload(),
              if (input.imageBase64 != null) 'imageBase64': input.imageBase64,
              if (input.mimeType != null) 'mimeType': input.mimeType,
            }),
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('AI ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException('invalid ai json');
      return mapGatewayPayload(
        decoded,
        sourceText: input.text,
      );
    } finally {
      if (owned) httpClient.close();
    }
  }

  /// Accepts the live gateway `{items:[...]}` shape and the canonical
  /// `{actions:[...]}` shape so a future gateway update is not required.
  static FamilyBrainAiResponse mapGatewayPayload(
    Map<dynamic, dynamic> json, {
    String sourceText = '',
  }) {
    if (json['actions'] is List) {
      return FamilyBrainAiResponse.fromJson(
        json,
        providerId: 'gemini',
        sourceText: sourceText,
      );
    }

    final actions = <FamilyBrainAiAction>[];
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is! Map) continue;
        final action = _actionFromGatewayItem(Map<String, dynamic>.from(item));
        if (action != null) actions.add(action);
      }
    }

    final clarification = _text(json['clarification']);
    if (clarification != null) {
      actions.add(
        FamilyBrainAiAction(
          type: FamilyBrainAiActionType.askForClarification,
          message: clarification,
        ),
      );
    }

    return FamilyBrainAiResponse(
      providerId: 'gemini',
      sourceText: sourceText,
      clarification: clarification,
      actions: actions,
    );
  }

  static FamilyBrainAiAction? _actionFromGatewayItem(Map<String, dynamic> item) {
    final rawType = (item['type'] ?? item['kind'] ?? 'task').toString().toLowerCase();
    final type = switch (rawType) {
      'event' => FamilyBrainAiActionType.createEvent,
      'reminder' => FamilyBrainAiActionType.createReminder,
      'list' => FamilyBrainAiActionType.createListItem,
      'information' || 'note' || 'info' => FamilyBrainAiActionType.createTask,
      'task' => FamilyBrainAiActionType.createTask,
      _ => FamilyBrainAiActionType.tryParse(rawType) ??
          FamilyBrainAiActionType.createTask,
    };
    final title = _text(item['title'] ?? item['listName']);
    final listItems = <String>[
      if (item['listItems'] is List)
        for (final entry in item['listItems'] as List)
          if (entry.toString().trim().isNotEmpty) entry.toString().trim(),
    ];
    if (title == null && listItems.isEmpty) return null;

    final assignee = item['assignee'] ??
        (item['people'] is List && (item['people'] as List).isNotEmpty
            ? (item['people'] as List).first
            : null);
    final confidence = item['confidence'];
    return FamilyBrainAiAction(
      type: type,
      title: title,
      description: _text(item['description']),
      date: _text(item['date']),
      time: _text(item['time']),
      reminderTime: _text(item['reminderTime'] ?? item['reminder']),
      hasDueTime: item['time'] != null || item['hasDueTime'] == true,
      priority: _text(item['priority']),
      status: _text(item['status']),
      space: _text(item['space']),
      assigneeName: assignee?.toString(),
      assigneeId: _text(item['assigneeId']),
      listItems: listItems,
      location: _text(item['location']),
      explanation: _text(item['explanation'] ?? item['context']),
      confidence: confidence is num ? confidence.toDouble() : null,
      kind: rawType == 'information' || rawType == 'note' || rawType == 'info'
          ? 'information'
          : rawType,
      lowConfidence:
          item['lowConfidence'] == true || (confidence is num && confidence < 0.55),
    );
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
