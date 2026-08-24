import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';
import '../config/app_config.dart';
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

/// Talks to the Family Brain AI gateway when [AppConfig.aiBackendUrl] is set.
/// Secrets stay on the server. Falls back to the on-device parser.
class FamilyBrainAi {
  static Future<BrainUnderstandResult> understand({
    required String text,
    required DateTime now,
    List<AppUser> members = const [],
    String? imagePath,
    String? imageBase64,
    String? mimeType,
    http.Client? client,
    Duration timeout = const Duration(seconds: 12),
    String? backendUrl,
  }) async {
    final url = _origin(backendUrl ?? AppConfig.aiBackendUrl);
    if (url.isNotEmpty) {
      try {
        final cloud = await _cloudUnderstand(
          url: url,
          text: text,
          now: now,
          members: members,
          imageBase64: imageBase64,
          mimeType: mimeType,
          client: client,
          timeout: timeout,
        );
        if (cloud.drafts.isNotEmpty) {
          return cloud;
        }
      } on SocketException {
        final local = FamilyBrainParser.parseAll(
          text,
          now: now,
          members: members,
          imagePath: imagePath,
        );
        return BrainUnderstandResult(
          drafts: local,
          originalText: text,
          usedFallback: true,
          error: 'offline',
        );
      } catch (_) {
        final local = FamilyBrainParser.parseAll(
          text,
          now: now,
          members: members,
          imagePath: imagePath,
        );
        return BrainUnderstandResult(
          drafts: local,
          originalText: text,
          usedFallback: true,
          error: 'ai_failed',
        );
      }
    }

    final local = FamilyBrainParser.parseAll(
      text,
      now: now,
      members: members,
      imagePath: imagePath,
    );
    return BrainUnderstandResult(drafts: local, originalText: text);
  }

  static String _origin(String url) => url.trim().replaceAll(RegExp(r'/+$'), '');

  static Future<BrainUnderstandResult> _cloudUnderstand({
    required String url,
    required String text,
    required DateTime now,
    required List<AppUser> members,
    String? imageBase64,
    String? mimeType,
    http.Client? client,
    required Duration timeout,
  }) async {
    final httpClient = client ?? http.Client();
    final owned = client == null;
    try {
      final response = await httpClient
          .post(
            Uri.parse('$url/understand'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'now': now.toIso8601String(),
              'language': 'en',
              'members': [
                for (final member in members)
                  {'id': member.id, 'name': member.name},
              ],
              if (imageBase64 != null) 'imageBase64': imageBase64,
              if (mimeType != null) 'mimeType': mimeType,
            }),
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('AI ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException('invalid ai json');
      final drafts = draftsFromAiJson(
        decoded,
        originalText: text,
        now: now,
        members: members,
      );
      return BrainUnderstandResult(
        drafts: drafts,
        originalText: text,
        usedCloud: drafts.isNotEmpty,
        clarification: decoded['clarification'] as String?,
      );
    } finally {
      if (owned) httpClient.close();
    }
  }

  static List<BrainDraft> draftsFromAiJson(
    Map<dynamic, dynamic> json, {
    required String originalText,
    required DateTime now,
    List<AppUser> members = const [],
  }) {
    final rawItems = json['items'];
    if (rawItems is! List) return const [];
    final drafts = <BrainDraft>[];
    for (final item in rawItems) {
      if (item is! Map) continue;
      final draft = _draftFromItem(
        Map<String, dynamic>.from(item),
        originalText: originalText,
        now: now,
        members: members,
      );
      if (draft != null) drafts.add(draft);
    }
    return drafts;
  }

  static BrainDraft? _draftFromItem(
    Map<String, dynamic> item, {
    required String originalText,
    required DateTime now,
    required List<AppUser> members,
  }) {
    final type = (item['type'] ?? item['kind'] ?? 'task').toString().toLowerCase();
    final kind = switch (type) {
      'event' => InformationKind.event,
      'reminder' => InformationKind.reminder,
      'list' => InformationKind.list,
      'information' || 'note' || 'info' => InformationKind.information,
      _ => InformationKind.task,
    };
    final title = (item['title'] ?? item['listName'] ?? '').toString().trim();
    final listItems = <String>[
      if (item['listItems'] is List)
        for (final entry in item['listItems'] as List)
          if (entry.toString().trim().isNotEmpty) entry.toString().trim(),
    ];
    if (title.isEmpty && listItems.isEmpty) return null;

    final due = _combineDateTime(item['date'], item['time'], now);
    final reminder = _combineDateTime(
          item['date'],
          item['reminderTime'] ?? item['reminder'],
          now,
        ) ??
        (kind == InformationKind.reminder ? due : null);
    final assigneeName = (item['assignee'] ??
            (item['people'] is List && (item['people'] as List).isNotEmpty
                ? (item['people'] as List).first
                : null))
        ?.toString();
    AppUser? member;
    if (assigneeName != null && assigneeName.trim().isNotEmpty) {
      final needle = assigneeName.toLowerCase();
      member = members
          .where(
            (m) =>
                needle.contains(m.name.toLowerCase()) ||
                m.name.toLowerCase().split(' ').any((part) => needle.contains(part)),
          )
          .firstOrNull;
    }

    final confidence = item['confidence'];
    final low = confidence is num ? confidence < 0.55 : item['lowConfidence'] == true;
    final space = (item['space'] ?? '').toString().toLowerCase();

    return BrainDraft(
      kind: kind,
      title: title.isEmpty ? listItems.join(', ') : title,
      originalText: originalText,
      dueDate: due,
      hasDueTime: item['time'] != null || item['hasDueTime'] == true,
      reminderAt: reminder,
      assigneeId: member?.id,
      assigneeName: member?.name ?? assigneeName,
      listItems: listItems,
      lowConfidence: low,
      description: item['description']?.toString(),
      location: item['location']?.toString(),
      explanation: item['explanation']?.toString() ?? item['context']?.toString(),
      personal: space == 'personal' || space == 'private',
    );
  }

  static DateTime? _combineDateTime(dynamic date, dynamic time, DateTime now) {
    DateTime? day;
    if (date is String && date.isNotEmpty) {
      day = DateTime.tryParse(date);
    }
    if (time is String && time.isNotEmpty) {
      final parts = time.split(':');
      final hour = int.tryParse(parts.first) ?? 0;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final base = day ?? DateTime(now.year, now.month, now.day);
      return DateTime(base.year, base.month, base.day, hour, minute);
    }
    return day;
  }
}
