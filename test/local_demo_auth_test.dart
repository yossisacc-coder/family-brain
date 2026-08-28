import 'package:family_brain/core/config/app_config.dart';
import 'package:family_brain/data/local/local_auth_repository.dart';
import 'package:family_brain/data/local/local_family_repository.dart';
import 'package:family_brain/data/local/local_json_store.dart';
import 'package:family_brain/data/local/local_notification_repository.dart';
import 'package:family_brain/data/local/local_task_repository.dart';
import 'package:family_brain/data/local/local_user_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo login seeds a family workspace without Firebase', () async {
    final store = LocalJsonStore(persist: false);
    final auth = LocalAuthRepository(store);
    final users = LocalUserRepository(store);
    final families = LocalFamilyRepository(store: store, users: users);
    final tasks = LocalTaskRepository(store);
    final notifications = LocalNotificationRepository(store);

    final user = await auth.signInWithDemoAccount(language: 'he');

    expect(user.id, AppConfig.demoUserId);
    expect(user.name, AppConfig.demoName);
    expect(user.language, 'he');
    expect(user.hasFamily, isTrue);
    expect(store.sessionUid, AppConfig.demoUserId);

    final family = await families.watchFamily(user.familyId!).first;
    expect(family?.name, AppConfig.demoFamilyName);
    expect(family?.memberIds, containsAll([
      user.id,
      AppConfig.demoPartnerId,
      AppConfig.demoChildId,
      AppConfig.demoDaughterId,
      AppConfig.demoGrandparentId,
    ]));

    final openTasks = await tasks.watchFamilyTasks(user.familyId!).first;
    expect(openTasks, isNotEmpty);
    expect(openTasks.any((task) => task.isUrgent), isTrue);
    expect(
      openTasks.any((task) => task.id == 'demo-task-maya-personal'),
      isTrue,
    );
    expect(
      openTasks
          .where((task) => task.isVisibleTo(user.id))
          .any((task) => task.id == 'demo-task-maya-personal'),
      isFalse,
    );

    final inbox = await notifications.watchUserNotifications(user.id).first;
    expect(inbox, isNotEmpty);
    expect(inbox.first.read, isFalse);

    await auth.signOut();
    expect(store.sessionUid, isNull);
    expect(await users.getUser(user.id), isNotNull);
  });

  test('demo login restores the same workspace after sign-out', () async {
    final store = LocalJsonStore(persist: false);
    final auth = LocalAuthRepository(store);
    await auth.signInWithDemoAccount(language: 'en');
    store.tasks.remove('demo-task-milk');
    await store.commit();
    await auth.signOut();

    final again = await auth.signInWithDemoAccount(language: 'en');
    expect(again.hasFamily, isTrue);
    expect(store.tasks.containsKey('demo-task-milk'), isFalse);
  });
}
