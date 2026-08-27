import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/brain/family_brain_ask.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/appearance.dart';
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
                  color: context.palette.textMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _AskComposer(
            controller: _question,
            onSubmit: _ask,
            enabled: true,
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

class _AskComposer extends StatefulWidget {
  const _AskComposer({
    required this.controller,
    required this.onSubmit,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool enabled;

  @override
  State<_AskComposer> createState() => _AskComposerState();
}

class _AskComposerState extends State<_AskComposer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant _AskComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSend => widget.controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final enabled = widget.enabled && _canSend;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 4, 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('ask-ai-input'),
                controller: widget.controller,
                minLines: 1,
                maxLines: 4,
                enabled: widget.enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? (_) => widget.onSubmit() : null,
                decoration: InputDecoration(
                  hintText: l10n.askExample,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            Tooltip(
              message: l10n.send,
              child: Material(
                key: const Key('ask-ai-send'),
                color: enabled ? palette.primary : palette.border,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: enabled ? widget.onSubmit : null,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.send_rounded,
                      color: enabled ? Colors.white : palette.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
