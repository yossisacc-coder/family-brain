import '../models/family_activity.dart';

abstract class ActivityRepository {
  Stream<List<FamilyActivity>> watchFamilyActivity({
    required String familyId,
    required String viewerId,
  });

  Future<void> addActivity(FamilyActivity activity);

  Future<void> deleteActivity(String activityId);

  Future<void> clearFamilyActivity(String familyId);
}
