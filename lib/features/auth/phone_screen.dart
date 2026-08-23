import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/providers.dart';
import '../settings/locale_controller.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      setState(() => _error = l10n.requiredField);
      return;
    }
    if (!_phone.text.contains(RegExp(r'\d{8,}'))) {
      setState(() => _error = l10n.invalidPhone);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final verification =
          await ref.read(authRepositoryProvider).sendPhoneCode(_phone.text);
      if (!mounted) return;
      context.push('/otp', extra: {
        'verificationId': verification.verificationId,
        'phone': _phone.text.trim(),
        'name': _name.text.trim(),
        'language': ref.read(localeControllerProvider).languageCode,
      });
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
      appBar: AppBar(title: Text(l10n.phoneTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            l10n.phoneSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.yourName,
              hintText: l10n.nameHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneHint,
              helperText: l10n.phoneHelper,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.urgent)),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: l10n.sendCode,
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
