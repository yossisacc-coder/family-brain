import 'package:flutter/material.dart';

/// Official Family Brain logo (08E — Two-tone).
class FamilyBrainLogoColors {
  static const navy = Color(0xFF012557);
  static const azure = Color(0xFF0568CA);
  static const charcoal = navy;
  static const iconNavy = navy;
}

class FamilyBrainLogoMark extends StatelessWidget {
  const FamilyBrainLogoMark({super.key, this.size = 44});

  static const asset = 'assets/brand/family_brain_mark.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Family Brain',
      image: true,
      child: Image.asset(
        asset,
        key: const Key('family-brain-logo'),
        width: size,
        height: size,
        filterQuality: FilterQuality.high,
        fit: BoxFit.contain,
        gaplessPlayback: true,
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
    final base = (compact
            ? Theme.of(context).textTheme.titleMedium
            : Theme.of(context).textTheme.titleLarge)
        ?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: compact ? 0 : -0.2,
          height: 1,
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
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Family ',
                    style: base?.copyWith(color: FamilyBrainLogoColors.navy),
                  ),
                  TextSpan(
                    text: 'Brain',
                    style: base?.copyWith(color: FamilyBrainLogoColors.azure),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class FamilyBrainAppIcon extends StatelessWidget {
  const FamilyBrainAppIcon({super.key, this.size = 64});

  static const asset = 'assets/brand/family_brain_app_icon.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Family Brain',
      image: true,
      child: Image.asset(
        asset,
        key: const Key('family-brain-app-icon'),
        width: size,
        height: size,
        filterQuality: FilterQuality.high,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }
}
