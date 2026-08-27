import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  @override
  Future<AppUser?> getUser(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists || snap.data() == null) return null;
    return AppUser.fromMap(snap.data()!);
  }

  @override
  Stream<AppUser?> watchUser(String id) {
    return _col.doc(id).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return AppUser.fromMap(snap.data()!);
    });
  }

  @override
  Future<void> saveUser(AppUser user) {
    return _col.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  @override
  Future<List<AppUser>> getUsers(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final users = <AppUser>[];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snap = await _col
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      users.addAll(snap.docs.map((doc) => AppUser.fromMap(doc.data())));
    }
    return users;
  }
}
