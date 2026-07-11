import 'package:equatable/equatable.dart';

enum NotificationType { info, success, alert }

/// A single in-app notification (pure model).
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.type,
    this.unread = false,
  });

  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final NotificationType type;
  final bool unread;

  AppNotification copyWith({bool? unread}) => AppNotification(
    id: id,
    title: title,
    body: body,
    timeLabel: timeLabel,
    type: type,
    unread: unread ?? this.unread,
  );

  @override
  List<Object> get props => [id, title, body, timeLabel, type, unread];
}
