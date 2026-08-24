import 'package:go_router/go_router.dart';

/// Decision for a system/hardware Android Back press.
enum AppBackAction { pop, go, exit }

class AppBackDecision {
  const AppBackDecision._(this.action, [this.location]);

  const AppBackDecision.pop() : this._(AppBackAction.pop);
  const AppBackDecision.go(String location)
      : this._(AppBackAction.go, location);
  const AppBackDecision.exit() : this._(AppBackAction.exit);

  final AppBackAction action;
  final String? location;
}

/// Shared Android Back policy for Family Brain.
///
/// Pop any in-app route first. From a bottom-nav tab other than Home, return
/// to Home. Only leave the app when the user is already on the root Home
/// screen (or another true root such as Welcome).
class AppBackNavigation {
  static const shellTabs = <String>{
    '/app/tasks',
    '/app/family',
    '/app/settings',
  };

  static AppBackDecision resolve({
    required bool canPop,
    required String path,
  }) {
    if (canPop) {
      return const AppBackDecision.pop();
    }
    final fallback = fallbackLocation(path);
    if (fallback != null) {
      return AppBackDecision.go(fallback);
    }
    return const AppBackDecision.exit();
  }

  static String? fallbackLocation(String path) {
    final edit = RegExp(r'^/tasks/([^/]+)/edit$').firstMatch(path);
    if (edit != null) {
      return '/tasks/${edit.group(1)}';
    }
    if (path == '/tasks/calendar' ||
        path == '/space/personal' ||
        path == '/space/family') {
      return '/app/home';
    }
    if (path == '/tasks/trash') {
      return '/app/tasks';
    }
    if (RegExp(r'^/family/members/[^/]+$').hasMatch(path)) {
      return '/app/family';
    }
    if (path == '/tasks/new' || RegExp(r'^/tasks/[^/]+$').hasMatch(path)) {
      return '/app/tasks';
    }
    if (path == '/notifications' || path == '/settings-public') {
      return '/app/home';
    }
    if (path == '/otp') {
      return '/login';
    }
    if (path == '/login') {
      return '/welcome';
    }
    if (shellTabs.contains(path)) {
      return '/app/home';
    }
    return null;
  }

  /// Returns `true` when the back press was consumed inside the app.
  static bool handle(GoRouter router) {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final decision = resolve(canPop: router.canPop(), path: path);
    switch (decision.action) {
      case AppBackAction.pop:
        router.pop();
        return true;
      case AppBackAction.go:
        router.go(decision.location!);
        return true;
      case AppBackAction.exit:
        return false;
    }
  }
}
