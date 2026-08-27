import 'package:family_brain/core/access/access_entitlement.dart';
import 'package:family_brain/core/brain/ai/ai_retry.dart';
import 'package:family_brain/core/notifications/local_reminder_scheduler.dart';
import 'package:family_brain/core/share/incoming_share.dart';
import 'package:family_brain/core/share/share_intake_controller.dart';
import 'package:family_brain/data/local/local_activity_repository.dart';
import 'package:family_brain/data/local/local_json_store.dart';
import 'package:family_brain/data/local/local_task_repository.dart';
import 'package:family_brain/domain/activity/activity_recorder.dart';
import 'package:family_brain/domain/models/app_user.dart';
import 'package:family_brain/domain/models/family_activity.dart';
import 'package:family_brain/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 27, 9);
  final alex = AppUser(
    id: 'alex',
    name: 'Alex',
    phone: '+1',
    language: 'en',
    createdAt: now,
    familyId: 'fam',
    plan: AccessPlan.beta,
    familyRole: FamilyRole.owner,
  );
  final maya = AppUser(
    id: 'maya',
    name: 'Maya',
    phone: '+2',
    language: 'en',
    createdAt: now,
    familyId: 'fam',
    plan: AccessPlan.beta,
    familyRole: FamilyRole.member,
  );

  group('incoming shared content', () {
    test('parses shared text and subject without duplicating the subject', () {
      final share = IncomingShare.fromMap({
        'shareId': 's1',
        'subject': 'School pickup',
        'text': 'School pickup\nMaya needs to pick up the kids tomorrow at 5 PM',
        'mimeType': 'text/plain',
        'source': 'android_share',
      });
      expect(share.hasText, isTrue);
      expect(share.hasImage, isFalse);
      expect(share.displayText, contains('Maya needs to pick up the kids'));
      expect(share.displayText.split('School pickup').length, 2);
      expect(share.source, 'android_share');
    });

    test('parses shared images and extra photo note', () {
      final share = IncomingShare.fromMap({
        'shareId': 'img-1',
        'mimeType': 'image/*',
        'imagePath': '/tmp/shared_one.png',
        'imagePaths': ['/tmp/shared_one.png', '/tmp/shared_two.jpg'],
        'text': 'Screenshot from WhatsApp',
      });
      expect(share.hasImage, isTrue);
      expect(share.imagePaths, hasLength(2));
      expect(share.imageMime, 'image/png');
      expect(share.composerText, contains('Screenshot from WhatsApp'));
      expect(share.composerText, contains('1 more photo attached'));
    });

    test('ShareIntakeController ignores empty and duplicate share ids', () {
      final controller = ShareIntakeController();
      controller.apply(const IncomingShare(id: 'empty'));
      expect(controller.state, isNull);

      controller.apply(
        IncomingShare.fromMap({
          'shareId': 'keep',
          'text': 'Buy milk tomorrow',
        }),
      );
      expect(controller.state?.id, 'keep');
      expect(controller.state?.text, 'Buy milk tomorrow');

      controller.apply(
        IncomingShare.fromMap({
          'shareId': 'keep',
          'text': 'Buy milk tomorrow evening',
        }),
      );
      expect(controller.state?.text, 'Buy milk tomorrow');

      controller.clear();
      expect(controller.state, isNull);
      controller.apply(
        IncomingShare.fromMap({
          'shareId': 'keep',
          'text': 'Buy milk tomorrow',
        }),
      );
      expect(controller.state, isNull);
    });
  });

  group('activity log and cleanup', () {
    test('records activity, hides personal items, and clear does not delete tasks',
        () async {
      final store = LocalJsonStore(persist: false);
      final activities = LocalActivityRepository(store);
      final tasks = LocalTaskRepository(store);
      final recorder = ActivityRecorder(activities);

      final task = TaskItem(
        id: 'task-1',
        familyId: 'fam',
        creatorId: alex.id,
        title: 'Buy milk',
        type: TaskType.family,
        priority: TaskPriority.normal,
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      await tasks.createTask(task);
      await recorder.record(
        actor: alex,
        familyId: 'fam',
        type: ActivityType.taskCreated,
        summary: task.title,
        task: task,
      );
      await recorder.record(
        actor: maya,
        familyId: 'fam',
        type: ActivityType.shareReceived,
        summary: 'Shared from another app',
        detail: 'Maya needs to buy milk tomorrow',
      );
      await activities.addActivity(
        FamilyActivity(
          id: 'personal-1',
          familyId: 'fam',
          actorId: maya.id,
          actorName: maya.name,
          type: ActivityType.taskCreated,
          summary: 'Private note',
          createdAt: now,
          personal: true,
          assigneeId: maya.id,
        ),
      );

      final forAlex = await activities
          .watchFamilyActivity(familyId: 'fam', viewerId: alex.id)
          .first;
      final forMaya = await activities
          .watchFamilyActivity(familyId: 'fam', viewerId: maya.id)
          .first;
      expect(forAlex.map((item) => item.summary), isNot(contains('Private note')));
      expect(forMaya.map((item) => item.summary), contains('Private note'));
      expect(forAlex, isNotEmpty);

      await activities.deleteActivity('personal-1');
      await activities.clearFamilyActivity('fam');

      expect(
        await activities.watchFamilyActivity(familyId: 'fam', viewerId: alex.id).first,
        isEmpty,
      );
      expect(store.tasks.containsKey('task-1'), isTrue);
      expect(
        await tasks.watchFamilyTasks('fam').first,
        hasLength(1),
      );
    });

    test('clearing older activity keeps recent records and tasks', () async {
      final store = LocalJsonStore(persist: false);
      final activities = LocalActivityRepository(store);
      final tasks = LocalTaskRepository(store);
      await tasks.createTask(
        TaskItem(
          id: 'keep-task',
          familyId: 'fam',
          creatorId: alex.id,
          title: 'Keep me',
          type: TaskType.family,
          priority: TaskPriority.normal,
          status: TaskStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await activities.addActivity(
        FamilyActivity(
          id: 'old',
          familyId: 'fam',
          actorId: alex.id,
          actorName: alex.name,
          type: ActivityType.taskCreated,
          summary: 'Old activity',
          createdAt: now.subtract(const Duration(days: 10)),
        ),
      );
      await activities.addActivity(
        FamilyActivity(
          id: 'new',
          familyId: 'fam',
          actorId: alex.id,
          actorName: alex.name,
          type: ActivityType.taskCreated,
          summary: 'New activity',
          createdAt: now,
        ),
      );
      await activities.clearOlderThan(
        familyId: 'fam',
        cutoff: now.subtract(const Duration(days: 7)),
      );
      final remaining = await activities
          .watchFamilyActivity(familyId: 'fam', viewerId: alex.id)
          .first;
      expect(remaining.map((item) => item.id), ['new']);
      expect(store.tasks.containsKey('keep-task'), isTrue);
    });
  });

  group('beta entitlement', () {
    test('beta users can use the product without payment and premium is prepared',
        () {
      expect(alex.plan, AccessPlan.beta);
      expect(alex.entitlementFor(familyCreatedBy: alex.id).canUseProduct, isTrue);
      expect(alex.entitlementFor(familyCreatedBy: alex.id).isPremium, isFalse);
      expect(alex.entitlementFor(familyCreatedBy: alex.id).isBeta, isTrue);
      expect(
        alex.entitlementFor(familyCreatedBy: alex.id).canClearFamilyActivity,
        isTrue,
      );
      expect(
        maya.entitlementFor(familyCreatedBy: alex.id).canClearFamilyActivity,
        isFalse,
      );
      expect(
        maya.copyWith(plan: AccessPlan.premium).entitlementFor().isPremium,
        isTrue,
      );
      expect(
        AppUser.fromMap(alex.toMap()).plan,
        AccessPlan.beta,
      );
    });
  });

  group('retry limits and reminders', () {
    test('automatic AI retries stop after two attempts', () async {
      var calls = 0;
      await expectLater(
        AiRetryPolicy.run(() async {
          calls += 1;
          throw Exception('fail');
        }),
        throwsA(isA<Exception>()),
      );
      expect(calls, AiRetryPolicy.maxAttempts);
      expect(AiRetryPolicy.maxAttempts, 2);
    });

    test('reminder ids stay stable and past times are not scheduled', () {
      LocalReminderScheduler.debugReset();
      final first = LocalReminderScheduler.notificationIdFor('task-a');
      final second = LocalReminderScheduler.notificationIdFor('task-a');
      expect(first, second);
      final now = DateTime(2026, 8, 27, 10);
      expect(
        LocalReminderScheduler.shouldSchedule(
          TaskItem(
            id: 'future',
            familyId: 'fam',
            creatorId: alex.id,
            title: 'Later',
            type: TaskType.family,
            kind: InformationKind.reminder,
            reminderAt: now.add(const Duration(hours: 2)),
            priority: TaskPriority.normal,
            status: TaskStatus.pending,
            createdAt: now,
            updatedAt: now,
          ),
          now,
        ),
        isTrue,
      );
      expect(
        LocalReminderScheduler.shouldSchedule(
          TaskItem(
            id: 'past',
            familyId: 'fam',
            creatorId: alex.id,
            title: 'Past',
            type: TaskType.family,
            kind: InformationKind.reminder,
            reminderAt: now.subtract(const Duration(hours: 1)),
            priority: TaskPriority.normal,
            status: TaskStatus.pending,
            createdAt: now,
            updatedAt: now,
          ),
          now,
        ),
        isFalse,
      );
    });
  });
}
