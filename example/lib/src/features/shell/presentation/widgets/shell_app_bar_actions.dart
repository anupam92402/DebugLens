import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../notifications/presentation/views/notifications_screen.dart';
import '../../../settings/presentation/views/settings_screen.dart';

/// The AppBar actions shared by every tab: notifications (with unread badge)
/// and settings. Both push full-screen routes on the ROOT navigator so they
/// cover the bottom bar — unlike tab-internal routes, which stay nested.
class ShellAppBarActions extends StatelessWidget {
  const ShellAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) => IconButton(
            tooltip: 'Notifications',
            onPressed: () => _openNotifications(context),
            icon: Badge(
              isLabelVisible: state.unreadCount > 0,
              label: Text('${state.unreadCount}'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: () => _openSettings(context),
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'notifications'),
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'settings'),
        builder: (_) => const SettingsScreen(),
      ),
    );
  }
}
