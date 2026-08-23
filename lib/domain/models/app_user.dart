class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.language,
    required this.createdAt,
    this.familyId,
    this.fcmToken,
  });

  final String id;
  final String name;
  final String phone;
  final String language;
  final DateTime createdAt;
  final String? familyId;
  final String? fcmToken;

  bool get hasFamily => familyId != null && familyId!.isNotEmpty;

  AppUser copyWith({
    String? name,
    String? language,
    String? familyId,
    String? fcmToken,
    bool clearFamily = false,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      phone: phone,
      language: language ?? this.language,
      createdAt: createdAt,
      familyId: clearFamily ? null : (familyId ?? this.familyId),
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'familyId': familyId,
      'fcmToken': fcmToken,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      language: map['language'] as String? ?? 'en',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      familyId: map['familyId'] as String?,
      fcmToken: map['fcmToken'] as String?,
    );
  }
}
