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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(
            onPressed: user == null
                ? null
                : () => ref
                    .read(notificationRepositoryProvider)
                    .markAllRead(user.id),
            child: Text(l10n.markAllRead),
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
              return NotificationItem(
                notification: item,
                onTap: () async {
                  await ref
                      .read(notificationRepositoryProvider)
                      .markRead(item.id);
                  if (item.taskId != null && context.mounted) {
                    context.push('/tasks/${item.taskId}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
