import 'package:uuid/uuid.dart';

import '../../core/access/access_entitlement.dart';
import '../../core/config/app_config.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/family.dart';
import '../../domain/models/task_item.dart';
import '../../domain/repositories/auth_repository.dart';
import 'local_json_store.dart';

/// Development/demo auth that never calls Firebase or SMS.
///
/// The real [FirebaseAuthRepository] Phone/OTP implementation is unchanged
/// and used when `BACKEND_MODE=firebase`.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._store);

  final LocalJsonStore _store;
  static const _uuid = Uuid();
  static const _localPhoneVerificationId = 'local-demo-phone';

  @override
  Stream<String?> authStateChanges() async* {
    yield _store.sessionUid;
    await for (final _ in _store.changes) {
      yield _store.sessionUid;
    }
  }

  @override
  Future<PhoneVerification> sendPhoneCode(String phoneNumber) async {
    final normalized = _normalizePhone(phoneNumber);
    if (normalized.length < 8) {
      throw StateError('invalid-phone');
    }
    return const PhoneVerification(verificationId: _localPhoneVerificationId);
  }

  @override
  Future<AppUser> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
    required String name,
    required String language,
    String? phoneNumber,
  }) async {
    if (verificationId != _localPhoneVerificationId ||
        smsCode.trim() != AppConfig.demoOtp) {
      throw StateError('invalid-otp');
    }
    final phone = phoneNumber == null || phoneNumber.isEmpty
        ? AppConfig.demoPhone
        : _normalizePhone(phoneNumber);
    final existing = _store.users.values
        .map(AppUser.fromMap)
        .where((user) => user.phone == phone)
        .toList();
    final user = existing.isEmpty
        ? AppUser(
            id: 'local-user-${_uuid.v4()}',
            name: name.isEmpty ? 'Family member' : name,
            phone: phone,
            language: language,
            createdAt: DateTime.now(),
          )
        : existing.first.copyWith(
            name: name.isEmpty ? existing.first.name : name,
            language: language,
          );
    _store.users[user.id] = user.toMap();
    _store.sessionUid = user.id;
    await _store.commit();
    return user;
  }

  @override
  Future<AppUser> signInWithDemoAccount({required String language}) async {
    await _ensureDemoWorkspace(language);
    _store.sessionUid = AppConfig.demoUserId;
    await _store.commit();
    return AppUser.fromMap(_store.users[AppConfig.demoUserId]!);
  }

  @override
  Future<void> signOut() async {
    _store.sessionUid = null;
    await _store.commit();
  }

  Future<void> _ensureDemoWorkspace(String language) async {
    final now = DateTime.now();
    final existing = _store.users[AppConfig.demoUserId];
    if (existing != null) {
      existing['language'] = language;
      return;
    }

    final alex = AppUser(
      id: AppConfig.demoUserId,
      name: AppConfig.demoName,
      phone: AppConfig.demoPhone,
      language: language,
      createdAt: now,
      familyId: AppConfig.demoFamilyId,
      plan: AccessPlan.beta,
      familyRole: FamilyRole.owner,
    );
    final maya = AppUser(
      id: AppConfig.demoPartnerId,
      name: AppConfig.demoPartnerName,
      phone: '+16505550000',
      language: language,
      createdAt: now,
      familyId: AppConfig.demoFamilyId,
      plan: AccessPlan.beta,
      familyRole: FamilyRole.member,
    );
    final family = Family(
      id: AppConfig.demoFamilyId,
      name: AppConfig.demoFamilyName,
      createdAt: now,
      createdBy: alex.id,
      inviteCode: AppConfig.demoInviteCode,
      memberIds: [alex.id, maya.id],
      workspaceType: AppConfig.defaultWorkspaceType,
    );
    final milk = TaskItem(
      id: 'demo-task-milk',
      familyId: family.id,
      creatorId: maya.id,
      title: 'Buy milk',
      assigneeId: alex.id,
      type: TaskType.family,
      dueDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
      hasDueTime: false,
      reminderAt: DateTime(now.year, now.month, now.day, 18).add(const Duration(days: 1)),
      priority: TaskPriority.urgent,
      notes: 'Demo task so Home and Tasks have something to open.',
      status: TaskStatus.pending,
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    );
    final teacher = TaskItem(
      id: 'demo-task-teacher',
      familyId: family.id,
      creatorId: alex.id,
      title: 'Meeting with teacher — math',
      kind: InformationKind.event,
      assigneeId: maya.id,
      type: TaskType.family,
      dueDate: DateTime(now.year, now.month, now.day, 10),
      hasDueTime: true,
      priority: TaskPriority.normal,
      status: TaskStatus.pending,
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now.subtract(const Duration(hours: 3)),
    );
    final soccer = TaskItem(
      id: 'demo-task-soccer',
      familyId: family.id,
      creatorId: alex.id,
      title: 'Soccer practice',
      kind: InformationKind.event,
      assigneeId: alex.id,
      type: TaskType.family,
      dueDate: DateTime(now.year, now.month, now.day, 16, 30),
      hasDueTime: true,
      priority: TaskPriority.normal,
      status: TaskStatus.pending,
      createdAt: now.subtract(const Duration(hours: 4)),
      updatedAt: now.subtract(const Duration(hours: 4)),
    );
    final dinner = TaskItem(
      id: 'demo-task-dinner',
      familyId: family.id,
      creatorId: maya.id,
      title: 'Family dinner',
      kind: InformationKind.event,
      type: TaskType.family,
      dueDate: DateTime(now.year, now.month, now.day, 19),
      hasDueTime: true,
      priority: TaskPriority.normal,
      status: TaskStatus.pending,
      createdAt: now.subtract(const Duration(hours: 5)),
      updatedAt: now.subtract(const Duration(hours: 5)),
    );
    final packBag = TaskItem(
      id: 'demo-task-pack',
      familyId: family.id,
      creatorId: alex.id,
      title: 'Pack water bottles',
      kind: InformationKind.reminder,
      assigneeId: alex.id,
      type: TaskType.family,
      reminderAt: DateTime(now.year, now.month, now.day, 15, 30),
      priority: TaskPriority.high,
      status: TaskStatus.pending,
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now.subtract(const Duration(hours: 1)),
    );
    final grandma = TaskItem(
      id: 'demo-task-grandma',
      familyId: family.id,
      creatorId: alex.id,
      title: 'Call grandma',
      assigneeId: alex.id,
      type: TaskType.personal,
      priority: TaskPriority.normal,
      status: TaskStatus.inProgress,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(hours: 5)),
    );
    final mayaPersonal = TaskItem(
      id: 'demo-task-maya-personal',
      familyId: family.id,
      creatorId: maya.id,
      title: 'Write in journal',
      assigneeId: maya.id,
      type: TaskType.personal,
      priority: TaskPriority.high,
      notes: 'Private to Maya — not shown in Family Space.',
      status: TaskStatus.pending,
      createdAt: now.subtract(const Duration(hours: 6)),
      updatedAt: now.subtract(const Duration(hours: 6)),
    );
    final assigned = AppNotification(
      id: 'demo-notif-assigned',
      userId: alex.id,
      familyId: family.id,
      type: NotificationType.taskAssigned,
      title: 'New task assigned to you',
      message: milk.title,
      read: false,
      createdAt: now.subtract(const Duration(hours: 2)),
      taskId: milk.id,
    );

    _store.users[alex.id] = alex.toMap();
    _store.users[maya.id] = maya.toMap();
    _store.families[family.id] = family.toMap();
    _store.tasks[milk.id] = milk.toMap();
    _store.tasks[teacher.id] = teacher.toMap();
    _store.tasks[soccer.id] = soccer.toMap();
    _store.tasks[dinner.id] = dinner.toMap();
    _store.tasks[packBag.id] = packBag.toMap();
    _store.tasks[grandma.id] = grandma.toMap();
    _store.tasks[mayaPersonal.id] = mayaPersonal.toMap();
    _store.notifications[assigned.id] = assigned.toMap();
  }

  String _normalizePhone(String value) {
    final compact = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (compact.startsWith('+')) return compact;
    return '+$compact';
  }
}
