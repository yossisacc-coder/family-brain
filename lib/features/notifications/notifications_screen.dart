import 'package:flutter/material.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/notification_item.dart';
import '../../data/providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(userNotificationsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final repo = ref.read(notificationRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(
            onPressed: user == null ? null : () => repo.markAllRead(user.id),
            child: Text(l10n.markAllRead),
          ),
          IconButton(
            tooltip: l10n.clearNotifications,
            onPressed: user == null
                ? null
                : () => _clearAll(context, ref, user.id, l10n),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: async.when(
        loading: () => LoadingView(label: l10n.loading),
        error: (_, _) => ErrorView(
          message: l10n.errorUnavailable,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(userNotificationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: l10n.noNotifications,
              message: l10n.noNotificationsMessage,
              icon: Icons.notifications_none_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: AlignmentDirectional.centerEnd,
                  padding: const EdgeInsetsDirectional.only(end: 20),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Icon(Icons.delete_outline),
                ),
                onDismissed: (_) async {
                  await repo.deleteNotification(item.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.notificationDeleted)),
                  );
                },
                child: NotificationItem(
                  notification: item,
                  unreadLabel: l10n.unread,
                  deleteLabel: l10n.deleteNotification,
                  onDelete: () async {
                    await repo.deleteNotification(item.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.notificationDeleted)),
                    );
                  },
                  onTap: () async {
                    await repo.markRead(item.id);
                    if (item.taskId != null && context.mounted) {
                      context.push('/tasks/${item.taskId}');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _clearAll(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearNotificationsTitle),
        content: Text(l10n.clearNotificationsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clearNotifications),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(notificationRepositoryProvider).clearNotifications(userId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.notificationsCleared)),
    );
  }
}
