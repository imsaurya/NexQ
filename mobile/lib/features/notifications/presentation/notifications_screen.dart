import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../models/app_notification.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/simple_auth.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentProfileProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    final notificationsAsync = ref.watch(_notificationsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref
                .read(notificationRepositoryProvider)
                .markAllAsRead(user.id),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _NotificationTile(notification: items[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

final _notificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null) {
    return const Stream.empty();
  }
  return ref
      .watch(notificationRepositoryProvider)
      .watchUserNotifications(userId);
});

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final time = DateFormat('MMM d, h:mm a').format(notification.createdAt);

    return Card(
      color: notification.isRead
          ? null
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: ListTile(
        onTap: () => ref
            .read(notificationRepositoryProvider)
            .markAsRead(notification.id),
        leading: Icon(_iconForType(notification.type)),
        title: Text(notification.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(time, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(NotificationType type) => switch (type) {
        NotificationType.requestApproved => Icons.check_circle,
        NotificationType.requestRejected => Icons.cancel,
        NotificationType.turnSoon => Icons.notifications_active,
        NotificationType.queuePaused => Icons.pause_circle,
        NotificationType.tokenSkipped => Icons.skip_next,
        NotificationType.general => Icons.info,
      };
}
