import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Official Family Brain logo (Logo 02).
///
/// Two overlapping rounded squares: charcoal left, violet right, with the
/// intersection punched out as negative space.
class FamilyBrainLogoColors {
  static const charcoal = Color(0xFF1A1C1E);
  static const violet = Color(0xFF635BFF);
  static const iconNavy = Color(0xFF0A0033);
}

enum FamilyBrainLogoVariant { mark, appIcon }

class FamilyBrainLogoMark extends StatelessWidget {
  const FamilyBrainLogoMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Family Brain',
      image: true,
      child: SizedBox(
        key: const Key('family-brain-logo'),
        width: size,
        height: size,
        child: CustomPaint(
          painter: FamilyBrainLogoPainter(variant: FamilyBrainLogoVariant.mark),
        ),
      ),
    );
  }
}

class FamilyBrainLogoLockup extends StatelessWidget {
  const FamilyBrainLogoLockup({
    super.key,
    this.markSize = 28,
    this.compact = false,
  });

  final double markSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = compact
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: FamilyBrainLogoColors.charcoal,
            );
    return Semantics(
      label: 'Family Brain',
      child: Row(
        key: const Key('family-brain-logo-lockup'),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          FamilyBrainLogoMark(size: markSize),
          SizedBox(width: compact ? 8 : 10),
          Flexible(
            child: Text(
              'Family Brain',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class FamilyBrainAppIcon extends StatelessWidget {
  const FamilyBrainAppIcon({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Family Brain',
      image: true,
      child: SizedBox(
        key: const Key('family-brain-app-icon'),
        width: size,
        height: size,
        child: CustomPaint(
          painter: FamilyBrainLogoPainter(
            variant: FamilyBrainLogoVariant.appIcon,
          ),
        ),
      ),
    );
  }
}

class FamilyBrainLogoPainter extends CustomPainter {
  const FamilyBrainLogoPainter({
    this.variant = FamilyBrainLogoVariant.mark,
  });

  final FamilyBrainLogoVariant variant;

  static Path tilePath(Offset center, double size, double radius, double angle) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: size,
            height: size,
          ),
          Radius.circular(radius),
        ),
      );
    final matrix = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..rotateZ(angle);
    return path.transform(matrix.storage);
  }

  static ({Path left, Path right, Path hole}) geometry(Size size) {
    final s = math.min(size.width, size.height);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final tile = s * 0.62;
    final radius = tile * 0.18;
    final offset = s * 0.07;
    const angle = 40 * math.pi / 180;
    final left = tilePath(Offset(cx - offset, cy), tile, radius, -angle);
    final right = tilePath(Offset(cx + offset, cy), tile, radius, angle);
    final hole = Path.combine(PathOperation.intersect, left, right);
    return (left: left, right: right, hole: hole);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shapes = geometry(size);

    if (variant == FamilyBrainLogoVariant.appIcon) {
      final radius = math.min(size.width, size.height) * 0.22;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
        Paint()..color = FamilyBrainLogoColors.iconNavy,
      );
    }

    canvas.saveLayer(Offset.zero & size, Paint());
    final leftPaint = Paint()
      ..color = variant == FamilyBrainLogoVariant.appIcon
          ? Colors.white
          : FamilyBrainLogoColors.charcoal
      ..isAntiAlias = true;
    final rightPaint = Paint()
      ..color = variant == FamilyBrainLogoVariant.appIcon
          ? Colors.white
          : FamilyBrainLogoColors.violet
      ..isAntiAlias = true;
    canvas.drawPath(shapes.left, leftPaint);
    canvas.drawPath(shapes.right, rightPaint);
    canvas.drawPath(
      shapes.hole,
      Paint()
        ..blendMode = BlendMode.clear
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FamilyBrainLogoPainter oldDelegate) {
    return oldDelegate.variant != variant;
  }
}
