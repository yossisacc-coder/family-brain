import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/appearance.dart';
import 'family_brain_logo.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: context.palette.primary,
                minimumSize: const Size(AppSpacing.touch, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.palette.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return FamilyBrainLogoMark(size: size);
  }
}
