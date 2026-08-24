import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:family_brain/core/widgets/task_trash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    TaskTrash.undoSnackBar(
                      l10n: l10n,
                      onUndo: () {},
                    ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    TaskTrash.undoSnackBar(
                      l10n: l10n,
                      onUndo: () => undone = true,
                    ),
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
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, isTrue);
    expect(find.text('Task moved to Trash'), findsNothing);
    expect(find.text('New task'), findsNothing);
  });
}
