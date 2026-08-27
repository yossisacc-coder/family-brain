import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/appearance.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? palette.card,
        borderRadius: AppRadii.card,
        border: Border.all(color: borderColor ?? palette.border),
        boxShadow: elevated ? AppShadows.cardFor(palette) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.card,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(
                padding: padding ?? const EdgeInsets.all(AppSpacing.card),
                child: child,
              )
            : InkWell(
                onTap: onTap,
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(AppSpacing.card),
                  child: child,
                ),
              ),
      ),
    );
  }
}
