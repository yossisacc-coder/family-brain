import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/appearance.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
    required this.onTap,
    this.icon,
    this.subtitle,
  });

  final String label;
  final int value;
  final Color color;
  final Color background;
  final VoidCallback onTap;
  final IconData? icon;
  final String? subtitle;

  static const double height = 88;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: SizedBox(
        height: height,
        child: Material(
          color: background,
          borderRadius: AppRadii.card,
          elevation: 0,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.card,
            child: Ink(
              decoration: BoxDecoration(
                color: background,
                borderRadius: AppRadii.card,
                boxShadow: AppShadows.card,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null)
                      Icon(icon, size: 16, color: color),
                    if (icon != null) const SizedBox(height: 6),
                    Text(
                      '$value',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                height: 1.2,
                              ),
                        ),
                      ),
                    ),
                    if (subtitle != null && subtitle != label)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
