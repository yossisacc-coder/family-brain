import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/access/access_entitlement.dart';
import '../../core/config/app_config.dart';
import '../../domain/models/family.dart';
import '../../domain/repositories/family_repository.dart';
import '../../domain/repositories/user_repository.dart';

class FirestoreFamilyRepository implements FamilyRepository {
  FirestoreFamilyRepository({
    required UserRepository users,
    FirebaseFirestore? firestore,
  })  : _users = users,
        _db = firestore ?? FirebaseFirestore.instance;

  final UserRepository _users;
  final FirebaseFirestore _db;
  final _random = Random.secure();

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('families');

  @override
  Stream<Family?> watchFamily(String familyId) {
    return _col.doc(familyId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Family.fromMap(snap.data()!);
    });
  }

  @override
  Future<Family> createFamily({
    required String name,
    required String creatorId,
  }) async {
    final id = _col.doc().id;
    final family = Family(
      id: id,
      name: name.trim(),
      createdAt: DateTime.now(),
      createdBy: creatorId,
      inviteCode: _inviteCode(),
      memberIds: [creatorId],
      workspaceType: AppConfig.defaultWorkspaceType,
    );
    await _col.doc(id).set(family.toMap());
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
    final snap = await _col
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      throw StateError('invalid-invite');
    }
    final family = Family.fromMap(snap.docs.first.data());
    final members = {...family.memberIds, userId}.toList();
    final updated = family.copyWith(memberIds: members);
    await _col.doc(family.id).set(updated.toMap(), SetOptions(merge: true));
    final user = await _users.getUser(userId);
    if (user != null) {
      await _users.saveUser(
        user.copyWith(familyId: family.id, familyRole: FamilyRole.member),
      );
    }
    return updated;
  }

  String _inviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }
}
