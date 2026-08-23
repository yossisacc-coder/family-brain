import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;

import '../core/config/app_config.dart';
import '../domain/models/app_notification.dart';
import '../domain/models/app_user.dart';
import '../domain/models/family.dart';
import '../domain/models/task_item.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/family_repository.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/repositories/user_repository.dart';
import 'firebase/firebase_auth_repository.dart';
import 'firebase/firestore_family_repository.dart';
import 'firebase/firestore_notification_repository.dart';
import 'firebase/firestore_task_repository.dart';
import 'firebase/firestore_user_repository.dart';
import 'firebase/notification_service.dart';
import 'local/local_auth_repository.dart';
import 'local/local_family_repository.dart';
import 'local/local_json_store.dart';
import 'local/local_notification_repository.dart';
import 'local/local_task_repository.dart';
import 'local/local_user_repository.dart';

final localStoreProvider = Provider<LocalJsonStore>((ref) {
  return LocalJsonStore();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (AppConfig.useLocalDemo) {
    return LocalUserRepository(ref.watch(localStoreProvider));
  }
  return FirestoreUserRepository();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useLocalDemo) {
    return LocalAuthRepository(ref.watch(localStoreProvider));
  }
  return FirebaseAuthRepository(users: ref.watch(userRepositoryProvider));
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  if (AppConfig.useLocalDemo) {
    return LocalFamilyRepository(
      store: ref.watch(localStoreProvider),
      users: ref.watch(userRepositoryProvider),
    );
  }
  return FirestoreFamilyRepository(users: ref.watch(userRepositoryProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  if (AppConfig.useLocalDemo) {
    return LocalTaskRepository(ref.watch(localStoreProvider));
  }
  return FirestoreTaskRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (AppConfig.useLocalDemo) {
    return LocalNotificationRepository(ref.watch(localStoreProvider));
  }
  return FirestoreNotificationRepository();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    notifications: ref.watch(notificationRepositoryProvider),
    users: ref.watch(userRepositoryProvider),
  );
});

final authUidProvider = StreamProvider<String?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(authUidProvider).valueOrNull;
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(uid);
});

final currentFamilyProvider = StreamProvider<Family?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final familyId = user?.familyId;
  if (familyId == null || familyId.isEmpty) return Stream.value(null);
  return ref.watch(familyRepositoryProvider).watchFamily(familyId);
});

final familyMembersProvider = FutureProvider<List<AppUser>>((ref) async {
  final family = ref.watch(currentFamilyProvider).valueOrNull;
  if (family == null) return const [];
  return ref.watch(userRepositoryProvider).getUsers(family.memberIds);
});

final familyTasksProvider = StreamProvider<List<TaskItem>>((ref) {
  final family = ref.watch(currentFamilyProvider).valueOrNull;
  if (family == null) return Stream.value(const []);
  return ref.watch(taskRepositoryProvider).watchFamilyTasks(family.id);
});

final userNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref
      .watch(notificationRepositoryProvider)
      .watchUserNotifications(user.id);
});

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(userNotificationsProvider).valueOrNull ?? [];
  return notifications.where((item) => !item.read).length;
});
