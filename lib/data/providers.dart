import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;

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

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(users: ref.watch(userRepositoryProvider));
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FirestoreFamilyRepository(users: ref.watch(userRepositoryProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return FirestoreTaskRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
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
