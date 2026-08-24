import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/providers.dart';

class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  final _familyName = TextEditingController();
  final _invite = TextEditingController();
  bool _creating = false;
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _familyName.dispose();
    _invite.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || _familyName.text.trim().isEmpty) {
      setState(() => _error = l10n.requiredField);
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      await ref.read(familyRepositoryProvider).createFamily(
            name: _familyName.text,
            creatorId: user.id,
          );
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || _invite.text.trim().isEmpty) {
      setState(() => _error = l10n.requiredField);
      return;
    }
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      await ref.read(familyRepositoryProvider).joinFamily(
            inviteCode: _invite.text,
            userId: user.id,
          );
    } catch (_) {
      setState(() => _error = l10n.invalidInvite);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.familySetupTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            l10n.familySetupSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.workspaceHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.createFamilyTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _familyName,
            decoration: InputDecoration(
              labelText: l10n.familyName,
              hintText: l10n.familyNameHint,
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: l10n.createFamilyAction,
            loading: _creating,
            onPressed: _create,
          ),
          const SizedBox(height: 28),
          Text(
            l10n.joinFamilyTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _invite,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.inviteCode,
              hintText: l10n.inviteCodeHint,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _joining ? null : _join,
            child: _joining
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.joinFamilyAction),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.urgent)),
          ],
        ],
      ),
    );
  }
}
