import 'dart:math';

import '../../core/access/access_entitlement.dart';
import '../../core/config/app_config.dart';
import '../../domain/models/family.dart';
import '../../domain/repositories/family_repository.dart';
import '../../domain/repositories/user_repository.dart';
import 'local_json_store.dart';

class LocalFamilyRepository implements FamilyRepository {
  LocalFamilyRepository({
    required LocalJsonStore this._store,
    required UserRepository this._users,
  });

  final LocalJsonStore _store;
  final UserRepository _users;
  final _random = Random();

  @override
  Stream<Family?> watchFamily(String familyId) async* {
    yield _read(familyId);
    await for (final _ in _store.changes) {
      yield _read(familyId);
    }
  }

  @override
  Future<Family> createFamily({
    required String name,
    required String creatorId,
  }) async {
    final id = 'local-family-${DateTime.now().microsecondsSinceEpoch}';
    final family = Family(
      id: id,
      name: name.trim(),
      createdAt: DateTime.now(),
      createdBy: creatorId,
      inviteCode: _inviteCode(),
      memberIds: [creatorId],
      workspaceType: AppConfig.defaultWorkspaceType,
    );
    _store.families[id] = family.toMap();
    await _store.commit();
    final user = await _users.getUser(creatorId);
    if (user != null) {
      await _users.saveUser(
        user.copyWith(familyId: id, familyRole: FamilyRole.owner),
      );
    }
    return family;
  }

  @override
  Future<Family> joinFamily({
    required String inviteCode,
    required String userId,
  }) async {
    final code = inviteCode.trim().toUpperCase();
    final match = _store.families.values
        .map(Family.fromMap)
        .where((family) => family.inviteCode.toUpperCase() == code)
        .toList();
    if (match.isEmpty) {
      throw StateError('invalid-invite');
    }
    final family = match.first;
    final members = {...family.memberIds, userId}.toList();
    final updated = family.copyWith(memberIds: members);
    _store.families[family.id] = updated.toMap();
    await _store.commit();
    final user = await _users.getUser(userId);
    if (user != null) {
      await _users.saveUser(
        user.copyWith(familyId: family.id, familyRole: FamilyRole.member),
      );
    }
    return updated;
  }

  Family? _read(String familyId) {
    final data = _store.families[familyId];
    if (data == null) return null;
    return Family.fromMap(data);
  }

  String _inviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }
}
