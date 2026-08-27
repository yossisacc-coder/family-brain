class IncomingShare {
  const IncomingShare({
    required this.id,
    this.text,
    this.subject,
    this.mimeType,
    this.imagePath,
    this.imagePaths = const [],
    this.source = 'android_share',
  });

  final String id;
  final String? text;
  final String? subject;
  final String? mimeType;
  final String? imagePath;
  final List<String> imagePaths;
  final String source;

  bool get hasText => (displayText).trim().isNotEmpty;

  bool get hasImage =>
      (imagePath != null && imagePath!.isNotEmpty) || imagePaths.isNotEmpty;

  bool get isEmpty => !hasText && !hasImage;

  String get displayText {
    final parts = <String>[
      if (subject != null && subject!.trim().isNotEmpty) subject!.trim(),
      if (text != null && text!.trim().isNotEmpty) text!.trim(),
    ];
    if (parts.length == 2 && parts[1].contains(parts[0])) {
      return parts[1];
    }
    return parts.join('\n');
  }

  String get composerText {
    final body = displayText;
    if (imagePaths.length <= 1) return body;
    final extra = imagePaths.length - 1;
    final note = extra == 1 ? '1 more photo attached' : '$extra more photos attached';
    return body.isEmpty ? note : '$body\n$note';
  }

  String get imageMime {
    final mime = mimeType;
    if (mime != null && mime.startsWith('image/') && mime != 'image/*') {
      return mime;
    }
    return mimeFromPath(imagePath);
  }

  static String mimeFromPath(String? path) {
    final lower = (path ?? '').toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  factory IncomingShare.fromMap(Map<dynamic, dynamic> payload) {
    final paths = <String>[];
    final rawPaths = payload['imagePaths'];
    if (rawPaths is List) {
      for (final item in rawPaths) {
        final path = item.toString().trim();
        if (path.isNotEmpty) paths.add(path);
      }
    }
    final single = payload['imagePath']?.toString().trim();
    if (single != null && single.isNotEmpty && !paths.contains(single)) {
      paths.insert(0, single);
    }
    return IncomingShare(
      id: payload['shareId']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      text: _text(payload['text']),
      subject: _text(payload['subject']),
      mimeType: _text(payload['mimeType']),
      imagePath: paths.isEmpty ? null : paths.first,
      imagePaths: paths,
      source: _text(payload['source']) ?? 'android_share',
    );
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
