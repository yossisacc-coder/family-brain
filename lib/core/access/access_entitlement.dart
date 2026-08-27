enum FamilyRole { owner, admin, member }

enum AccessPlan { beta, premium }

/// Access layer for Beta now and Premium later. Beta is never paywalled.
class AccessEntitlement {
  const AccessEntitlement({
    required this.plan,
    required this.role,
  });

  final AccessPlan plan;
  final FamilyRole role;

  bool get canUseProduct => true;

  bool get isPremium => plan == AccessPlan.premium;

  bool get isBeta => plan == AccessPlan.beta;

  bool get canClearFamilyActivity =>
      role == FamilyRole.owner || role == FamilyRole.admin;

  static AccessPlan planFromName(String? raw) {
    return AccessPlan.values.where((value) => value.name == raw).firstOrNull ??
        AccessPlan.beta;
  }

  static FamilyRole roleFromName(String? raw) {
    return FamilyRole.values.where((value) => value.name == raw).firstOrNull ??
        FamilyRole.member;
  }
}
