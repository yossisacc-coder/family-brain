import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/firebase/firebase_bootstrap.dart';
import 'data/local/local_json_store.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
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
