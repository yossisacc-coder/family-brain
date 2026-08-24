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
  tearDown(TaskTrash.dismiss);

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

  Widget harness({
    required Widget Function(BuildContext context, WidgetRef ref) body,
    List<Override> overrides = const [],
    Widget? fab,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          floatingActionButton: fab,
          body: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: TrashUndoBar(),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) => body(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('trash undo snackbar auto-dismisses after about 3 seconds',
      (tester) async {
    await tester.pumpWidget(
      harness(
        body: (context, ref) {
          return FilledButton(
            onPressed: () {
              TaskTrash.showUndo(ref: ref, task: sampleTask());
            },
            child: const Text('Trash'),
          );
        },
      ),
    );

    await tester.tap(find.text('Trash'));
    await tester.pump();
    expect(find.text('Task moved to Trash'), findsOneWidget);

    await tester.pump(TaskTrash.undoDuration);
    await tester.pump();
    expect(find.text('Task moved to Trash'), findsNothing);
  });

  testWidgets('tapping Undo restores instead of opening a new task',
      (tester) async {
    var undone = false;
    final repo = LocalTaskRepository(LocalJsonStore(persist: false));
    await tester.pumpWidget(
      harness(
        overrides: [taskRepositoryProvider.overrideWithValue(repo)],
        fab: FloatingActionButton.extended(
          onPressed: () {},
          label: const Text('Add task'),
        ),
        body: (context, ref) {
          return FilledButton(
            onPressed: () {
              TaskTrash.showUndo(
                ref: ref,
                task: sampleTask(),
                onUndo: () => undone = true,
              );
            },
            child: const Text('Trash'),
          );
        },
      ),
    );

    await tester.tap(find.text('Trash'));
    await tester.pump();
    await tester.tap(find.byKey(TaskTrash.undoButtonKey));
    await tester.pumpAndSettle();
    expect(undone, isTrue);
    expect(find.text('Task moved to Trash'), findsNothing);
    expect(find.text('New task'), findsNothing);
  });

  testWidgets('Undo restores a trashed task from the Tasks banner',
      (tester) async {
    final store = LocalJsonStore(persist: false);
    final repo = LocalTaskRepository(store);
    final task = sampleTask();
    await repo.createTask(task);

    await tester.pumpWidget(
      harness(
        overrides: [taskRepositoryProvider.overrideWithValue(repo)],
        fab: FloatingActionButton.extended(
          onPressed: () {},
          label: const Text('Add task'),
        ),
        body: (context, ref) {
          return FilledButton(
            onPressed: () {
              TaskTrash.move(
                context: context,
                ref: ref,
                task: task,
                l10n: AppLocalizations.of(context),
              );
            },
            child: const Text('Delete'),
          );
        },
      ),
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await repo.watchFamilyTasks('family-1').first, isEmpty);
    expect(
      (await repo.watchTrashedTasks('family-1').first).single.isTrashed,
      isTrue,
    );
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
