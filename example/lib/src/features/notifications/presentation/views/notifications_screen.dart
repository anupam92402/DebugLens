import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/notifications_cubit.dart';
import '../widgets/notification_tile.dart';

/// Full-screen notifications list, opened from the AppBar bell icon.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) => TextButton(
              onPressed: state.unreadCount == 0
                  ? null
                  : () => context.read<NotificationsCubit>().markAllRead(),
              child: const Text('Mark all read'),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.items.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                NotificationTile(notification: state.items[index]),
          );
        },
      ),
    );
  }
}
