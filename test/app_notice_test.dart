import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:family_brain/core/routing/root_keys.dart';
import 'package:family_brain/core/widgets/app_notice.dart';
import 'package:family_brain/core/widgets/task_trash.dart';
import 'package:family_brain/data/local/local_json_store.dart';
import 'package:family_brain/data/local/local_task_repository.dart';
import 'package:family_brain/domain/models/task_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    AppNotice.lastLocation = null;
    TaskTrash.dismiss();
  });

  testWidgets('temporary notices dismiss immediately on location change', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox.expand()),
      ),
    );

    AppNotice.show(null, 'Task moved to Trash');
    await tester.pump();
    expect(find.text('Task moved to Trash'), findsOneWidget);

    AppNotice.onLocation('/app/home');
    await tester.pump();
    expect(find.text('Task moved to Trash'), findsNothing);
  });

  testWidgets('undo banner is not dismissed by navigation and expires in 3s', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: TrashUndoBar(),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    return FilledButton(
                      onPressed: () {
                        TaskTrash.showUndo(
                          ref: ref,
                          task: TaskItem(
                            id: 'task-1',
                            familyId: 'family-1',
                            creatorId: 'alex',
                            title: 'Buy milk',
                            type: TaskType.family,
                            priority: TaskPriority.normal,
                            status: TaskStatus.pending,
                            createdAt: DateTime(2026, 8, 24),
                            updatedAt: DateTime(2026, 8, 24),
                          ),
                          repo: LocalTaskRepository(
                            LocalJsonStore(persist: false),
                          ),
                        );
                      },
                      child: const Text('Trash'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Trash'));
    await tester.pump();
    expect(find.text('Task moved to Trash'), findsOneWidget);

    AppNotice.onLocation('/app/home');
    await tester.pump();
    expect(find.text('Task moved to Trash'), findsOneWidget);

    await tester.pump(TaskTrash.undoDuration);
    await tester.pump();
    expect(find.text('Task moved to Trash'), findsNothing);
  });
}
