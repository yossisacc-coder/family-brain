import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/models/family_activity.dart';
import '../../domain/models/task_item.dart';

Future<void> recordFamilyActivity(
  WidgetRef ref, {
  required ActivityType type,
  required String summary,
  String? detail,
  TaskItem? task,
  bool? personal,
}) async {
  final user = ref.read(currentUserProvider).valueOrNull;
  final family = ref.read(currentFamilyProvider).valueOrNull;
  final familyId = family?.id ?? user?.familyId;
  if (user == null || familyId == null || familyId.isEmpty) return;
  await ref.read(activityRecorderProvider).record(
        actor: user,
        familyId: familyId,
        type: type,
        summary: summary,
        detail: detail,
        task: task,
        personal: personal,
      );
}
