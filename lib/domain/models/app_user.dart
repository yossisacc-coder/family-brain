class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.language,
    required this.createdAt,
    this.familyId,
    this.fcmToken,
    this.sharePhone = false,
  });

  final String id;
  final String name;
  final String phone;
  final String language;
  final DateTime createdAt;
  final String? familyId;
  final String? fcmToken;
  final bool sharePhone;

  bool get hasFamily => familyId != null && familyId!.isNotEmpty;

  /// Phone is only shown for calling/contact when the member chose to share it,
  /// or when viewing your own profile.
  bool phoneVisibleTo(String viewerId) => id == viewerId || sharePhone;

  AppUser copyWith({
    String? name,
    String? language,
    String? familyId,
    String? fcmToken,
    bool? sharePhone,
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
      sharePhone: sharePhone ?? this.sharePhone,
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
      'sharePhone': sharePhone,
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
      sharePhone: map['sharePhone'] as bool? ?? false,
    );
  }
}
