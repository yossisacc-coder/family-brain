/// Family is the first workspace type on the Family Brain platform.
class Family {
  const Family({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.createdBy,
    required this.inviteCode,
    required this.memberIds,
    this.workspaceType = 'family',
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String createdBy;
  final String inviteCode;
  final List<String> memberIds;
  final String workspaceType;

  Family copyWith({String? name, List<String>? memberIds}) {
    return Family(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      createdBy: createdBy,
      inviteCode: inviteCode,
      memberIds: memberIds ?? this.memberIds,
      workspaceType: workspaceType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'inviteCode': inviteCode,
      'memberIds': memberIds,
      'workspaceType': workspaceType,
    };
  }

  factory Family.fromMap(Map<String, dynamic> map) {
    return Family(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
      inviteCode: map['inviteCode'] as String? ?? '',
      memberIds: List<String>.from(map['memberIds'] as List? ?? const []),
      workspaceType: map['workspaceType'] as String? ?? 'family',
    );
  }
}
