import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/brain/family_brain_parser.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../data/providers.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';

class BrainConfirmScreen extends ConsumerStatefulWidget {
  const BrainConfirmScreen({super.key});

  @override
  ConsumerState<BrainConfirmScreen> createState() => _BrainConfirmScreenState();
}

class _BrainConfirmScreenState extends ConsumerState<BrainConfirmScreen> {
  BrainDraft? _draft;
  var _editing = false;
  var _saving = false;
  String? _error;
  late final TextEditingController _title;
  late final TextEditingController _items;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(pendingBrainDraftProvider);
    _title = TextEditingController(text: _draft?.title ?? '');
    _items = TextEditingController(text: _draft?.listItems.join('\n') ?? '');
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
    final draft = _draft;
    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.brainUnderstood)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.brainUnclear,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: l10n.home,
                  onPressed: () => context.go('/app/home'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final members = ref.watch(familyMembersProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.brainUnderstood),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.cancel,
          onPressed: _cancel,
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
          if (draft.lowConfidence) ...[
            Text(
              l10n.brainUnclear,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCard(
            child: _editing ? _editForm(l10n, members, draft) : _summary(l10n, draft),
          ),
          if (!_editing &&
              draft.imagePath != null &&
              draft.imagePath!.isNotEmpty &&
              !kIsWeb) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(draft.imagePath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
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
            onPressed: _saving ? null : _cancel,
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _summary(AppLocalizations l10n, BrainDraft draft) {
    final rows = <(String, String)>[
      (l10n.brainType, _kindLabel(l10n, draft.kind)),
      (l10n.taskTitle, draft.title),
    ];
    if (draft.dueDate != null) {
      rows.add((l10n.brainDate, DateFormat.yMMMd().format(draft.dueDate!)));
      if (draft.hasDueTime) {
        rows.add((l10n.brainTime, DateFormat.Hm().format(draft.dueDate!)));
      }
    }
    if (draft.assigneeName != null) {
      rows.add((l10n.brainPerson, draft.assigneeName!));
    }
    if (draft.listItems.isNotEmpty) {
      rows.add((l10n.listItems, draft.listItems.join(', ')));
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

  Widget _editForm(
    AppLocalizations l10n,
    List<AppUser> members,
    BrainDraft draft,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<InformationKind>(
          // ignore: deprecated_member_use
          value: draft.kind,
          decoration: InputDecoration(labelText: l10n.brainType),
          items: [
            for (final kind in InformationKind.values)
              DropdownMenuItem(
                value: kind,
                child: Text(_kindLabel(l10n, kind)),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _draft = draft.copyWith(kind: value));
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _title,
          decoration: InputDecoration(labelText: l10n.taskTitle),
        ),
        if (draft.kind == InformationKind.list) ...[
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
            value: draft.assigneeId,
            decoration: InputDecoration(labelText: l10n.brainPerson),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.unassigned)),
              for (final member in members)
                DropdownMenuItem(value: member.id, child: Text(member.name)),
            ],
            onChanged: (value) {
              final member = members.where((m) => m.id == value).firstOrNull;
              setState(() {
                _draft = draft.copyWith(
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

  void _cancel() {
    ref.read(pendingBrainDraftProvider.notifier).state = null;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app/home');
    }
  }

  void _applyEdits(List<AppUser> members) {
    final draft = _draft;
    if (draft == null) return;
    final items = _items.text
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    _draft = draft.copyWith(
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
    final draft = _draft;
    if (draft == null || draft.title.trim().isEmpty) {
      setState(() => _error = l10n.requiredField);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final task = draft.toTaskItem(
        id: const Uuid().v4(),
        familyId: user.familyId!,
        creatorId: user.id,
      );
      await ref.read(taskRepositoryProvider).createTask(task);
      if (!mounted) return;
      ref.read(pendingBrainDraftProvider.notifier).state = null;
      context.go('/app/home');
      AppNotice.showAfterNavigation(l10n.brainSaved);
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
