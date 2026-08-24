import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:family_brain/core/routing/root_keys.dart';
import 'package:family_brain/core/widgets/app_notice.dart';
import 'package:family_brain/core/widgets/task_trash.dart';
import 'package:flutter/material.dart';
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
}
