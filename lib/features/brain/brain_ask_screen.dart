import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/brain/family_brain_ask.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/providers.dart';
import '../../domain/models/task_item.dart';
import '../../features/settings/locale_controller.dart';

class BrainAskScreen extends ConsumerStatefulWidget {
  const BrainAskScreen({super.key});

  @override
  ConsumerState<BrainAskScreen> createState() => _BrainAskScreenState();
}

class _BrainAskScreenState extends ConsumerState<BrainAskScreen> {
  final _question = TextEditingController();
  String? _answer;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.askFamilyBrain)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          32,
        ),
        children: [
          Text(
            l10n.askFamilyBrainHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _question,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _ask(),
            decoration: InputDecoration(hintText: l10n.askExample),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: l10n.askSubmit,
            icon: Icons.auto_awesome_outlined,
            onPressed: _ask,
          ),
          if (_answer != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: Text(
                _answer!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _ask() {
    final user = ref.read(currentUserProvider).valueOrNull;
    final locale = ref.read(localeControllerProvider);
    final all = ref.read(familyTasksProvider).valueOrNull ?? const [];
    final visible = user == null
        ? all.where((task) => task.type == TaskType.family)
        : all.where((task) => task.isVisibleTo(user.id));
    setState(() {
      _answer = FamilyBrainAsk.answer(
        question: _question.text,
        visibleTasks: visible.toList(),
        now: DateTime.now(),
        languageCode: locale.languageCode,
      );
    });
  }
}
