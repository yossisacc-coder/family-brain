import 'package:family_brain/core/widgets/empty_state.dart';
import 'package:family_brain/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty state shows action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EmptyState(
            title: 'No tasks yet',
            message: 'Add one',
            actionLabel: 'Add your first task',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('No tasks yet'), findsOneWidget);
    await tester.tap(find.text('Add your first task'));
    expect(tapped, isTrue);
  });

  testWidgets('primary button can be pressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Save',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Save'));
    expect(tapped, isTrue);
  });
}
