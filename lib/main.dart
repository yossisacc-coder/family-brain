import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'core/notifications/local_reminder_scheduler.dart';
import 'core/routing/root_keys.dart';
import 'data/firebase/firebase_bootstrap.dart';
import 'data/local/local_json_store.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  try {
    await LocalReminderScheduler.initialize();
  } catch (_) {}
  LocalReminderScheduler.onTap = (taskId) {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      context.go('/tasks/$taskId');
    }
  };
  final store = LocalJsonStore();
  await store.load();
  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
      ],
      child: const FamilyBrainApp(),
    ),
  );
}
