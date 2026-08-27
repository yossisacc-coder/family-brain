import 'package:flutter/material.dart';

import '../routing/root_keys.dart';

/// Short-lived status messages. Always 2 seconds, and always cleared when the
/// route changes so they cannot stick to the app shell.
/// Trash Undo is separate ([TaskTrash.undoDuration], ~3 seconds) and is not
/// cleared by navigation — it auto-dismisses on its own timer.
class AppNotice {
  static const duration = Duration(seconds: 2);

  static String? lastLocation;
  static VoidCallback? onDismissedForNavigation;

  static void show(
    BuildContext? context,
    String message, {
    SnackBarAction? action,
  }) {
    final bar = SnackBar(
      duration: duration,
      content: Text(message),
      action: action,
    );
    final root = rootScaffoldMessengerKey.currentState;
    if (root != null) {
      root
        ..hideCurrentSnackBar()
        ..showSnackBar(bar);
      return;
    }
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(bar);
    }
  }

  /// Use when the current route is about to change so the message appears
  /// on the destination screen instead of being cleared by navigation.
  static void showAfterNavigation(
    String message, {
    SnackBarAction? action,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      show(null, message, action: action);
    });
  }

  static void dismissTransient() {
    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    rootScaffoldMessengerKey.currentState?.clearSnackBars();
    onDismissedForNavigation?.call();
  }

  static void onLocation(String location) {
    if (location == lastLocation) return;
    lastLocation = location;
    dismissTransient();
  }
}
