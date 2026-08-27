import '../models/app_user.dart';

abstract class UserRepository {
  Future<AppUser?> getUser(String id);

  Stream<AppUser?> watchUser(String id);

  Future<void> saveUser(AppUser user);

  Future<List<AppUser>> getUsers(List<String> ids);
}
