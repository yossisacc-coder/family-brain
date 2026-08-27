import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/family_activity.dart';
import '../models/task_item.dart';
import '../repositories/activity_repository.dart';

class ActivityRecorder {
  ActivityRecorder(this._repo);

  final ActivityRepository _repo;
  static const _uuid = Uuid();

  Future<void> record({
    required AppUser actor,
    required String familyId,
    required ActivityType type,
    required String summary,
    String? detail,
    TaskItem? task,
    bool? personal,
  }) {
    return _repo.addActivity(
      FamilyActivity(
        id: _uuid.v4(),
        familyId: familyId,
        actorId: actor.id,
        actorName: actor.name,
        type: type,
        summary: _clip(summary),
        detail: detail == null ? null : _clip(detail),
        createdAt: DateTime.now(),
        taskId: task?.id,
        taskTitle: task?.title,
        assigneeId: task?.assigneeId,
        personal: personal ?? task?.type == TaskType.personal,
      ),
    );
  }

  static String _clip(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 180) return trimmed;
    return '${trimmed.substring(0, 177)}…';
  }
}
