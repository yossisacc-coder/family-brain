import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Keeps a phone-first layout even when the preview is opened on a wide screen.
class PhoneShell extends StatelessWidget {
  const PhoneShell({super.key, required this.child});

  final Widget child;

  static const double maxPhoneWidth = 430;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxPhoneWidth + 24) {
          return child;
        }
        return ColoredBox(
          color: const Color(0xFFE8E2D8),
          child: Center(
            child: Container(
              width: maxPhoneWidth,
              height: constraints.maxHeight.clamp(640, 920),
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFD7D0C4), width: 8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 30,
                    offset: Offset(0, 16),
                  ),
                ],
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
