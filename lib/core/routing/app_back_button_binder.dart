import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_back_navigation.dart';

/// Intercepts the Android system/hardware Back button for [GoRouter].
class AppBackButtonBinder extends StatelessWidget {
  const AppBackButtonBinder({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () async {
        return AppBackNavigation.handle(GoRouter.of(context));
      },
      child: child,
    );
  }
}
