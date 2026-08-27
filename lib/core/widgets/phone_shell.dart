import 'package:flutter/material.dart';

import '../theme/app_shadows.dart';
import '../theme/appearance.dart';

/// Keeps a phone-first layout even when the preview is opened on a wide screen.
class PhoneShell extends StatelessWidget {
  const PhoneShell({super.key, required this.child});

  final Widget child;

  static const double maxPhoneWidth = 430;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxPhoneWidth + 24) {
          return child;
        }
        return ColoredBox(
          color: palette.desktopBackdrop,
          child: Center(
            child: Container(
              width: maxPhoneWidth,
              height: constraints.maxHeight.clamp(640, 920),
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: palette.border, width: 8),
                boxShadow: AppShadows.phone,
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
