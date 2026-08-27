import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/appearance.dart';

enum BrainStatusKind { listening, sending, success, error, info }

/// Single professional status area for Family Brain composer feedback.
class BrainStatusStrip extends StatelessWidget {
  const BrainStatusStrip({
    super.key,
    required this.message,
    required this.kind,
    this.retryLabel,
    this.onRetry,
  });

  final String message;
  final BrainStatusKind kind;
  final String? retryLabel;
  final VoidCallback? onRetry;

  static const stripKey = Key('brain-status-strip');

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = switch (kind) {
      BrainStatusKind.listening => palette.primary,
      BrainStatusKind.sending => palette.primary,
      BrainStatusKind.success => const Color(0xFF2F9B6E),
      BrainStatusKind.error => const Color(0xFFD94B4B),
      BrainStatusKind.info => palette.textMuted,
    };
    final icon = switch (kind) {
      BrainStatusKind.listening => Icons.mic_none_rounded,
      BrainStatusKind.sending => Icons.auto_awesome_rounded,
      BrainStatusKind.success => Icons.check_circle_outline_rounded,
      BrainStatusKind.error => Icons.error_outline_rounded,
      BrainStatusKind.info => Icons.info_outline_rounded,
    };
    return Material(
      key: stripKey,
      color: color.withValues(alpha: 0.08),
      borderRadius: AppRadii.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
              ),
            ),
            if (kind == BrainStatusKind.error && onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRetry,
                child: Text(retryLabel ?? 'Retry'),
              ),
            ] else if (kind == BrainStatusKind.sending ||
                kind == BrainStatusKind.listening) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
