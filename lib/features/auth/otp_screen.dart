import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phone,
    required this.name,
    required this.language,
  });

  final String verificationId;
  final String phone;
  final String name;
  final String language;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context);
    if (_code.text.trim().length < 6) {
      setState(() => _error = l10n.invalidOtp);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyPhoneCode(
            verificationId: widget.verificationId,
            smsCode: _code.text.trim(),
            name: widget.name,
            language: widget.language,
            phoneNumber: widget.phone,
          );
    } catch (_) {
      setState(() => _error = l10n.invalidOtp);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.otpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            l10n.otpSubtitle(widget.phone),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.urgent)),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: l10n.verifyCode,
            loading: _loading,
            onPressed: _verify,
          ),
        ],
      ),
    );
  }
}
