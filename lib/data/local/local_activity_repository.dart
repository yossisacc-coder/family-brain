import '../../domain/models/family_activity.dart';
import '../../domain/repositories/activity_repository.dart';
import 'local_json_store.dart';

class LocalActivityRepository implements ActivityRepository {
  LocalActivityRepository(this._store);

  final LocalJsonStore _store;

  @override
  Stream<List<FamilyActivity>> watchFamilyActivity({
    required String familyId,
    required String viewerId,
  }) async* {
    yield _list(familyId, viewerId);
    await for (final _ in _store.changes) {
      yield _list(familyId, viewerId);
    }
  }

  @override
  Future<void> addActivity(FamilyActivity activity) async {
    _store.activity[activity.id] = activity.toMap();
    await _store.commit();
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    _store.activity.remove(activityId);
    await _store.commit();
  }

  @override
  Future<void> clearFamilyActivity(String familyId) async {
    final ids = _store.activity.values
        .map(FamilyActivity.fromMap)
        .where((item) => item.familyId == familyId)
        .map((item) => item.id)
        .toList();
    for (final id in ids) {
      _store.activity.remove(id);
    }
    await _store.commit();
  }

  List<FamilyActivity> _list(String familyId, String viewerId) {
    return _store.activity.values
        .map(FamilyActivity.fromMap)
        .where((item) => item.familyId == familyId && item.isVisibleTo(viewerId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
