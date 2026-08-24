import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:family_brain/core/widgets/task_trash.dart';
import 'package:family_brain/data/local/local_json_store.dart';
import 'package:family_brain/data/local/local_task_repository.dart';
import 'package:family_brain/data/providers.dart';
import 'package:family_brain/domain/models/task_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TaskItem sampleTask() {
    return TaskItem(
      id: 'task-1',
      familyId: 'family-1',
      creatorId: 'alex',
      title: 'Buy milk',
      type: TaskType.family,
      priority: TaskPriority.normal,
      status: TaskStatus.pending,
      createdAt: DateTime(2026, 8, 24),
      updatedAt: DateTime(2026, 8, 24),
    );
  }

  testWidgets('trash undo snackbar auto-dismisses after about 3 seconds',
      (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return FilledButton(
                onPressed: () {
                  TaskTrash.showUndo(
                    context: context,
                    l10n: l10n,
                    onUndo: () {},
                  );
                },
                child: const Text('Trash'),
              );
            },
          ),
        ),
      ),
    );

    final bar = TaskTrash.undoSnackBar(l10n: l10n, onUndo: () {});
    expect(bar.persist, isFalse);
    expect(bar.action, isNull);
    expect(bar.duration, TaskTrash.undoDuration);

    await tester.tap(find.text('Trash'));
    await tester.pumpAndSettle();
    expect(find.text('Task moved to Trash'), findsOneWidget);

    await tester.pump(TaskTrash.undoDuration);
    await tester.pumpAndSettle();
    expect(find.text('Task moved to Trash'), findsNothing);
  });

  testWidgets('tapping Undo restores instead of opening a new task',
      (tester) async {
    late AppLocalizations l10n;
    var undone = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {},
            label: const Text('Add task'),
          ),
          body: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return FilledButton(
                onPressed: () {
                  TaskTrash.showUndo(
                    context: context,
                    l10n: l10n,
                    onUndo: () => undone = true,
                  );
                },
                child: const Text('Trash'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Trash'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TaskTrash.undoButtonKey));
    await tester.pumpAndSettle();
    expect(undone, isTrue);
    expect(find.text('Task moved to Trash'), findsNothing);
    expect(find.text('New task'), findsNothing);
  });

  testWidgets('Undo restores a trashed task above the shell Add task button',
      (tester) async {
    final store = LocalJsonStore(persist: false);
    final repo = LocalTaskRepository(store);
    final task = sampleTask();
    await repo.createTask(task);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final l10n = AppLocalizations.of(context);
                  return FilledButton(
                    onPressed: () {
                      TaskTrash.move(
                        context: context,
                        ref: ref,
                        task: task,
                        l10n: l10n,
                      );
                    },
                    child: const Text('Delete'),
                  );
                },
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {},
              label: const Text('Add task'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await repo.watchFamilyTasks('family-1').first, isEmpty);
    expect((await repo.watchTrashedTasks('family-1').first).single.isTrashed, isTrue);
    expect(find.text('Task moved to Trash'), findsOneWidget);

    await tester.tap(find.byKey(TaskTrash.undoButtonKey));
    await tester.pumpAndSettle();

    expect(
      (await repo.watchFamilyTasks('family-1').first).single.isTrashed,
      isFalse,
    );
    expect(await repo.watchTrashedTasks('family-1').first, isEmpty);
    expect(find.text('Task moved to Trash'), findsNothing);
  });
}
