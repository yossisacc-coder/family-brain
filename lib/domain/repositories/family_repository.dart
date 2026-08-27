import '../models/family.dart';

abstract class FamilyRepository {
  Stream<Family?> watchFamily(String familyId);

  Future<Family> createFamily({
    required String name,
    required String creatorId,
  });

  Future<Family> joinFamily({
    required String inviteCode,
    required String userId,
  });
}
