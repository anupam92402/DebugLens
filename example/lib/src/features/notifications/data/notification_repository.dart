import '../domain/app_notification.dart';

/// Dummy data source for notifications.
class NotificationRepository {
  Future<List<AppNotification>> fetchNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const [
      AppNotification(
        id: 'n1',
        title: 'Weekly report ready',
        body: 'Your insights for last week are ready to view.',
        timeLabel: '5m ago',
        type: NotificationType.info,
        unread: true,
      ),
      AppNotification(
        id: 'n2',
        title: 'Workout goal hit 🎉',
        body: 'You completed 4 of 5 planned workouts.',
        timeLabel: '1h ago',
        type: NotificationType.success,
        unread: true,
      ),
      AppNotification(
        id: 'n3',
        title: 'Bill due tomorrow',
        body: 'Electricity bill of ₹2,340 is due on 12 Jul.',
        timeLabel: '3h ago',
        type: NotificationType.alert,
        unread: true,
      ),
      AppNotification(
        id: 'n4',
        title: 'New feature: Insights',
        body: 'Track weekly progress across all your goals.',
        timeLabel: 'Yesterday',
        type: NotificationType.info,
      ),
      AppNotification(
        id: 'n5',
        title: 'Budget update',
        body: 'You have used 64% of this month\'s budget.',
        timeLabel: 'Yesterday',
        type: NotificationType.alert,
      ),
      AppNotification(
        id: 'n6',
        title: 'Backup complete',
        body: 'Your data was backed up successfully.',
        timeLabel: '2d ago',
        type: NotificationType.success,
      ),
    ];
  }
}
