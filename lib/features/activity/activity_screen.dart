import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/appearance.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_notice.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../data/providers.dart';
import '../../domain/models/family_activity.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final _selected = <String>{};

  Future<void> _confirmClear(AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.activityClearTitle),
        content: Text(l10n.activityClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.activityClearConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final family = ref.read(currentFamilyProvider).valueOrNull;
    if (family == null) return;
    await ref.read(activityRepositoryProvider).clearFamilyActivity(family.id);
    if (!mounted) return;
    setState(() => _selected.clear());
    AppNotice.show(context, l10n.activityCleared);
  }

  Future<void> _deleteSelected(AppLocalizations l10n) async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.activityDeleteSelectedTitle),
        content: Text(l10n.activityDeleteSelectedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.activityDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final repo = ref.read(activityRepositoryProvider);
    for (final id in _selected.toList()) {
      await repo.deleteActivity(id);
    }
    if (!mounted) return;
    setState(() => _selected.clear());
  }

  Future<void> _deleteOne(String id) {
    return ref.read(activityRepositoryProvider).deleteActivity(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(familyActivityProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final family = ref.watch(currentFamilyProvider).valueOrNull;
    final entitlement = user?.entitlementFor(familyCreatedBy: family?.createdBy);
    final canClear = entitlement?.canClearFamilyActivity ?? false;
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activityTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/app/home');
            }
          },
        ),
        actions: [
          if (_selected.isNotEmpty)
            IconButton(
              tooltip: l10n.activityDeleteSelected,
              onPressed: () => _deleteSelected(l10n),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          if (canClear)
            IconButton(
              tooltip: l10n.activityClear,
              onPressed: () => _confirmClear(l10n),
              icon: const Icon(Icons.cleaning_services_outlined),
            ),
        ],
      ),
      body: async.when(
        loading: () => LoadingView(label: l10n.loading),
        error: (_, _) => ErrorView(
          message: l10n.errorUnavailable,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(familyActivityProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.timeline_rounded,
              title: l10n.activityEmptyTitle,
              message: l10n.activityEmptyBody,
            );
          }
          return ListView.separated(
            key: const Key('activity-list'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              8,
              AppSpacing.page,
              32,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = _selected.contains(item.id);
              final canDelete = user != null &&
                  (item.actorId == user.id || canClear);
              final tile = AppCard(
                child: InkWell(
                  onLongPress: canDelete
                      ? () {
                          setState(() {
                            if (selected) {
                              _selected.remove(item.id);
                            } else {
                              _selected.add(item.id);
                            }
                          });
                        }
                      : null,
                  onTap: _selected.isEmpty
                      ? null
                      : () {
                          if (!canDelete) return;
                          setState(() {
                            if (selected) {
                              _selected.remove(item.id);
                            } else {
                              _selected.add(item.id);
                            }
                          });
                        },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_iconFor(item.type), color: palette.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titleFor(l10n, item.type),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.summary,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (item.detail != null && item.detail!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.detail!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: palette.textMuted),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              '${item.actorName} · ${_when(item.createdAt)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: palette.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
              if (!canDelete) return tile;
              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: AlignmentDirectional.centerEnd,
                  padding: const EdgeInsetsDirectional.only(end: 20),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Icon(Icons.delete_outline),
                ),
                onDismissed: (_) => _deleteOne(item.id),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: selected
                        ? Border.all(color: palette.primary, width: 2)
                        : null,
                  ),
                  child: tile,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _when(DateTime at) {
    final local = at.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hh:$mm';
  }

  IconData _iconFor(ActivityType type) {
    return switch (type) {
      ActivityType.taskCreated => Icons.add_task_rounded,
      ActivityType.taskCompleted => Icons.check_circle_outline_rounded,
      ActivityType.taskEdited => Icons.edit_outlined,
      ActivityType.taskDeleted => Icons.delete_outline_rounded,
      ActivityType.taskRestored => Icons.restore_from_trash_outlined,
      ActivityType.taskAssigned => Icons.person_add_alt_1_outlined,
      ActivityType.aiCreated => Icons.auto_awesome_rounded,
      ActivityType.shareReceived => Icons.ios_share_rounded,
      ActivityType.reminderSet => Icons.notifications_active_outlined,
    };
  }

  String _titleFor(AppLocalizations l10n, ActivityType type) {
    return switch (type) {
      ActivityType.taskCreated => l10n.activityTypeCreated,
      ActivityType.taskCompleted => l10n.activityTypeCompleted,
      ActivityType.taskEdited => l10n.activityTypeEdited,
      ActivityType.taskDeleted => l10n.activityTypeDeleted,
      ActivityType.taskRestored => l10n.activityTypeRestored,
      ActivityType.taskAssigned => l10n.activityTypeAssigned,
      ActivityType.aiCreated => l10n.activityTypeAi,
      ActivityType.shareReceived => l10n.activityTypeShare,
      ActivityType.reminderSet => l10n.activityTypeReminder,
    };
  }
}
