import '../../domain/models/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import 'local_json_store.dart';

class LocalUserRepository implements UserRepository {
  LocalUserRepository(this._store);

  final LocalJsonStore _store;

  @override
  Future<AppUser?> getUser(String id) async {
    final data = _store.users[id];
    if (data == null) return null;
    return AppUser.fromMap(data);
  }

  @override
  Stream<AppUser?> watchUser(String id) async* {
    yield await getUser(id);
    await for (final _ in _store.changes) {
      yield await getUser(id);
    }
  }

  @override
  Future<void> saveUser(AppUser user) async {
    _store.users[user.id] = user.toMap();
    await _store.commit();
  }

  @override
  Future<List<AppUser>> getUsers(List<String> ids) async {
    return ids
        .map((id) => _store.users[id])
        .whereType<Map<String, dynamic>>()
        .map(AppUser.fromMap)
        .toList();
  }
}
