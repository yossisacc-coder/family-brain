import 'ai/family_brain_context.dart';

/// Resolves personal vs family-wide vs a specific member.
///
/// Never invents a person. If two members match, the result is ambiguous
/// and the caller should ask for confirmation instead of guessing.
class AssignmentDecision {
  const AssignmentDecision({
    this.assigneeId,
    this.assigneeName,
    this.personal = false,
    this.familyWide = false,
    this.ambiguous = false,
  });

  final String? assigneeId;
  final String? assigneeName;
  final bool personal;
  final bool familyWide;
  final bool ambiguous;

  bool get hasAssignee => assigneeId != null && assigneeId!.isNotEmpty;
}

class AssignmentResolver {
  static final _familyWide = RegExp(
    r"\b(everyone|every one|all of us|the whole family|whole family|"
    r"the family|family needs|for the family|for everyone)\b",
    caseSensitive: false,
  );

  static final _familyWideHe = RegExp(
    r'כולם|לכולם|כולנו|כל המשפחה|לכל המשפחה|המשפחה כולה',
    unicode: true,
  );

  static final _personalSelf = RegExp(
    r"\b(i need to|i have to|i should|i must|i will|i'll|"
    r"remind me|for me|just me|only me|my space|private)\b",
    caseSensitive: false,
  );

  static final _personalSelfHe = RegExp(
    r'אני צריך|אני צריכה|תזכיר לי|רק לי|לעצמי|המרחב שלי',
    unicode: true,
  );

  static final _assignOther = RegExp(
    r"\b(?:i need|ask|tell|remind|assign)\s+([A-Za-z][\w'-]+)\b",
    caseSensitive: false,
  );

  static AssignmentDecision resolve({
    required String text,
    required List<FamilyBrainMemberRef> members,
    FamilyBrainMemberRef? currentUser,
    String? hintedId,
    String? hintedName,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty &&
        (hintedId == null || hintedId.isEmpty) &&
        (hintedName == null || hintedName.trim().isEmpty)) {
      return const AssignmentDecision();
    }

    if (_isFamilyWide(trimmed)) {
      return const AssignmentDecision(familyWide: true);
    }

    final hinted = _uniqueMember(
      members,
      id: hintedId,
      name: hintedName,
    );
    if (hinted.ambiguous) {
      return const AssignmentDecision(ambiguous: true);
    }

    final namedInText = _membersMentioned(trimmed, members);
    if (namedInText.length > 1) {
      return const AssignmentDecision(ambiguous: true);
    }

    final other = _explicitOther(trimmed, members);
    if (other.ambiguous) {
      return const AssignmentDecision(ambiguous: true);
    }
    if (other.member != null) {
      return AssignmentDecision(
        assigneeId: other.member!.id,
        assigneeName: other.member!.name,
      );
    }

    if (namedInText.length == 1) {
      final member = namedInText.first;
      return AssignmentDecision(
        assigneeId: member.id,
        assigneeName: member.name,
      );
    }

    if (_isPersonalSelf(trimmed) && currentUser != null) {
      return AssignmentDecision(
        assigneeId: currentUser.id,
        assigneeName: currentUser.name,
        personal: true,
      );
    }

    if (hinted.member != null) {
      return AssignmentDecision(
        assigneeId: hinted.member!.id,
        assigneeName: hinted.member!.name,
        personal: _isPersonalSelf(trimmed),
      );
    }

    if (_isPersonalSelf(trimmed)) {
      return const AssignmentDecision(personal: true);
    }

    return const AssignmentDecision();
  }

  static bool _isFamilyWide(String text) {
    return _familyWide.hasMatch(text) || _familyWideHe.hasMatch(text);
  }

  static bool _isPersonalSelf(String text) {
    if (_assignOther.hasMatch(text)) {
      final name = _assignOther.firstMatch(text)?.group(1)?.toLowerCase();
      if (name != null && !_stopWords.contains(name)) {
        return false;
      }
    }
    return _personalSelf.hasMatch(text) || _personalSelfHe.hasMatch(text);
  }

  static ({FamilyBrainMemberRef? member, bool ambiguous}) _explicitOther(
    String text,
    List<FamilyBrainMemberRef> members,
  ) {
    final match = _assignOther.firstMatch(text);
    final token = match?.group(1);
    if (token == null) return (member: null, ambiguous: false);
    final lower = token.toLowerCase();
    if (_stopWords.contains(lower)) {
      return (member: null, ambiguous: false);
    }
    return _uniqueMember(members, name: token);
  }

  static const _stopWords = {
    'me',
    'myself',
    'us',
    'to',
    'a',
    'an',
    'the',
    'my',
    'our',
    'some',
    'someone',
    'him',
    'her',
    'them',
  };

  static List<FamilyBrainMemberRef> _membersMentioned(
    String text,
    List<FamilyBrainMemberRef> members,
  ) {
    final hits = <FamilyBrainMemberRef>[];
    for (final member in members) {
      if (_nameOccurs(text, member.name)) hits.add(member);
    }
    if (hits.length <= 1) return hits;
    hits.sort((a, b) => b.name.length.compareTo(a.name.length));
    final longest = hits.first;
    final nested = hits
        .where(
          (other) =>
              other.id != longest.id &&
              longest.name.toLowerCase().contains(other.name.toLowerCase()),
        )
        .toList();
    if (nested.length == hits.length - 1) return [longest];
    return hits;
  }

  static ({FamilyBrainMemberRef? member, bool ambiguous}) _uniqueMember(
    List<FamilyBrainMemberRef> members, {
    String? id,
    String? name,
  }) {
    if (id != null && id.trim().isNotEmpty) {
      final match = members.where((member) => member.id == id.trim());
      if (match.length == 1) return (member: match.first, ambiguous: false);
      if (match.length > 1) return (member: null, ambiguous: true);
    }
    final needle = name?.trim() ?? '';
    if (needle.isEmpty) return (member: null, ambiguous: false);
    final hits = members.where((member) => _nameOccurs(needle, member.name) ||
        _nameOccurs(member.name, needle)).toList();
    if (hits.length > 1) {
      hits.sort((a, b) => b.name.length.compareTo(a.name.length));
      final longest = hits.first;
      final restAreParts = hits.skip(1).every(
            (other) => longest.name.toLowerCase().contains(other.name.toLowerCase()),
          );
      if (restAreParts) return (member: longest, ambiguous: false);
      return (member: null, ambiguous: true);
    }
    if (hits.length == 1) return (member: hits.first, ambiguous: false);
    return (member: null, ambiguous: false);
  }

  static bool _nameOccurs(String haystack, String name) {
    final trimmed = name.trim();
    if (trimmed.length < 2) return false;
    final lower = haystack.toLowerCase();
    final needle = trimmed.toLowerCase();
    final hebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(needle);
    if (hebrew) {
      return RegExp(
        '(?:^|[^\\u0590-\\u05FF])${RegExp.escape(needle)}(?:\$|[^\\u0590-\\u05FF])',
        unicode: true,
      ).hasMatch(haystack);
    }
    if (RegExp('\\b${RegExp.escape(needle)}\\b').hasMatch(lower)) return true;
    for (final part in needle.split(RegExp(r'\s+')).where((p) => p.length > 1)) {
      if (RegExp('\\b${RegExp.escape(part)}\\b').hasMatch(lower)) return true;
    }
    return false;
  }
}
