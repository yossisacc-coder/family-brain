import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/brain/family_brain_parser.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../data/providers.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';

class BrainConfirmScreen extends ConsumerStatefulWidget {
  const BrainConfirmScreen({super.key, required this.draft});

  final BrainDraft draft;

  @override
  ConsumerState<BrainConfirmScreen> createState() => _BrainConfirmScreenState();
}

class _BrainConfirmScreenState extends ConsumerState<BrainConfirmScreen> {
  late BrainDraft _draft;
  var _editing = false;
  var _saving = false;
  String? _error;
  late final TextEditingController _title;
  late final TextEditingController _items;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _title = TextEditingController(text: _draft.title);
    _items = TextEditingController(text: _draft.listItems.join('\n'));
  }

  @override
  void dispose() {
    _title.dispose();
    _items.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final members = ref.watch(familyMembersProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.brainUnderstood),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.cancel,
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          32,
        ),
        children: [
          if (_draft.lowConfidence) ...[
            Text(
              l10n.brainUnclear,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCard(
            child: _editing ? _editForm(l10n, members) : _summary(l10n),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: const TextStyle(color: AppColors.urgent)),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: l10n.confirm,
            loading: _saving,
            icon: Icons.check_rounded,
            onPressed: _saving ? null : () => _save(l10n),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: _editing ? l10n.continueAction : l10n.edit,
            icon: _editing ? Icons.visibility_outlined : Icons.edit_outlined,
            onPressed: _saving
                ? null
                : () => setState(() {
                      if (_editing) _applyEdits(members);
                      _editing = !_editing;
                    }),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _saving ? null : () => context.pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _summary(AppLocalizations l10n) {
    final rows = <(String, String)>[
      (l10n.brainType, _kindLabel(l10n, _draft.kind)),
      (l10n.taskTitle, _draft.title),
    ];
    if (_draft.dueDate != null) {
      rows.add((l10n.brainDate, DateFormat.yMMMd().format(_draft.dueDate!)));
      if (_draft.hasDueTime) {
        rows.add((l10n.brainTime, DateFormat.Hm().format(_draft.dueDate!)));
      }
    }
    if (_draft.assigneeName != null) {
      rows.add((l10n.brainPerson, _draft.assigneeName!));
    }
    if (_draft.listItems.isNotEmpty) {
      rows.add((l10n.listItems, _draft.listItems.join(', ')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows) ...[
          Text(
            row.$1,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(row.$2, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _editForm(AppLocalizations l10n, List<AppUser> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<InformationKind>(
          // ignore: deprecated_member_use
          value: _draft.kind,
          decoration: InputDecoration(labelText: l10n.brainType),
          items: [
            for (final kind in InformationKind.values)
              DropdownMenuItem(
                value: kind,
                child: Text(_kindLabel(l10n, kind)),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _draft = _draft.copyWith(kind: value));
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _title,
          decoration: InputDecoration(labelText: l10n.taskTitle),
        ),
        if (_draft.kind == InformationKind.list) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _items,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: l10n.listItems,
              hintText: l10n.listItemsHint,
            ),
          ),
        ],
        if (members.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            // ignore: deprecated_member_use
            value: _draft.assigneeId,
            decoration: InputDecoration(labelText: l10n.brainPerson),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.unassigned)),
              for (final member in members)
                DropdownMenuItem(value: member.id, child: Text(member.name)),
            ],
            onChanged: (value) {
              final member = members.where((m) => m.id == value).firstOrNull;
              setState(() {
                _draft = _draft.copyWith(
                  assigneeId: value,
                  assigneeName: member?.name,
                  clearAssignee: value == null,
                );
              });
            },
          ),
        ],
      ],
    );
  }

  void _applyEdits(List<AppUser> members) {
    final items = _items.text
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    _draft = _draft.copyWith(
      title: _title.text.trim(),
      listItems: items,
    );
  }

  Future<void> _save(AppLocalizations l10n) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || !user.hasFamily) {
      setState(() => _error = l10n.errorUnavailable);
      return;
    }
    _applyEdits(ref.read(familyMembersProvider).valueOrNull ?? const []);
    if (_draft.title.trim().isEmpty) {
      setState(() => _error = l10n.requiredField);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final task = _draft.toTaskItem(
        id: const Uuid().v4(),
        familyId: user.familyId!,
        creatorId: user.id,
      );
      await ref.read(taskRepositoryProvider).createTask(task);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.brainSaved)),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.errorUnavailable;
      });
    }
  }

  String _kindLabel(AppLocalizations l10n, InformationKind kind) {
    return switch (kind) {
      InformationKind.task => l10n.kindTask,
      InformationKind.event => l10n.kindEvent,
      InformationKind.reminder => l10n.kindReminder,
      InformationKind.list => l10n.kindList,
    };
  }
}
