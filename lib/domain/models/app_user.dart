import '../../core/access/access_entitlement.dart';

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
    this.plan = AccessPlan.beta,
    this.familyRole = FamilyRole.member,
  });

  final String id;
  final String name;
  final String phone;
  final String language;
  final DateTime createdAt;
  final String? familyId;
  final String? fcmToken;
  final bool sharePhone;
  final AccessPlan plan;
  final FamilyRole familyRole;

  bool get hasFamily => familyId != null && familyId!.isNotEmpty;

  AccessEntitlement entitlementFor({String? familyCreatedBy}) {
    final role = familyCreatedBy == id ? FamilyRole.owner : familyRole;
    return AccessEntitlement(plan: plan, role: role);
  }

  /// Phone is only shown for calling/contact when the member chose to share it,
  /// or when viewing your own profile.
  bool phoneVisibleTo(String viewerId) => id == viewerId || sharePhone;

  AppUser copyWith({
    String? name,
    String? language,
    String? familyId,
    String? fcmToken,
    bool? sharePhone,
    AccessPlan? plan,
    FamilyRole? familyRole,
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
      plan: plan ?? this.plan,
      familyRole: familyRole ?? this.familyRole,
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
      'plan': plan.name,
      'familyRole': familyRole.name,
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
      plan: AccessEntitlement.planFromName(map['plan'] as String?),
      familyRole: AccessEntitlement.roleFromName(map['familyRole'] as String?),
    );
  }
}
