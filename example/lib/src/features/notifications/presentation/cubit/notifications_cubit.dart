import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/notification_repository.dart';
import '../../domain/app_notification.dart';

final class NotificationsState extends Equatable {
  const NotificationsState({this.loading = true, this.items = const []});

  final bool loading;
  final List<AppNotification> items;

  int get unreadCount => items.where((n) => n.unread).length;

  @override
  List<Object> get props => [loading, items];
}

/// View-model for the notifications screen (and the AppBar badge).
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());

  final NotificationRepository _repository;

  Future<void> load() async {
    final items = await _repository.fetchNotifications();
    emit(NotificationsState(loading: false, items: items));
  }

  void markAllRead() {
    emit(
      NotificationsState(
        loading: state.loading,
        items: [for (final n in state.items) n.copyWith(unread: false)],
      ),
    );
  }
}
