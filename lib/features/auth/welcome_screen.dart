import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/providers.dart';
import '../settings/locale_controller.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _demo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final locale = ref.read(localeControllerProvider);
      await ref.read(authRepositoryProvider).signInWithDemoAccount(
            language: locale.languageCode,
          );
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => context.push('/settings-public'),
                  child: Text(l10n.language),
                ),
              ),
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.welcomeTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.welcomeSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
              ),
              const Spacer(),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppColors.urgent)),
                const SizedBox(height: 12),
              ],
              _DemoLoginCard(
                loading: _loading,
                onPressed: _demo,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.orDivider,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: l10n.continueWithPhone,
                icon: Icons.phone_iphone_rounded,
                onPressed: _loading ? null : () => context.push('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoLoginCard extends StatelessWidget {
  const _DemoLoginCard({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.urgentSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.demoModeLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: loading ? null : onPressed,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.science_outlined),
            label: Text(l10n.demoSignIn),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.demoHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
          ),
          if (AppConfig.useLocalDemo) ...[
            const SizedBox(height: 6),
            Text(
              l10n.demoModeSettings,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
