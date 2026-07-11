part of 'home_bloc.dart';

enum HomeStatus { loading, ready }

final class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.activities = const [],
  });

  final HomeStatus status;
  final List<Activity> activities;

  int get completedCount =>
      activities.where((activity) => activity.isDone).length;

  int get pendingCount => activities.length - completedCount;

  HomeState copyWith({HomeStatus? status, List<Activity>? activities}) =>
      HomeState(
        status: status ?? this.status,
        activities: activities ?? this.activities,
      );

  @override
  List<Object> get props => [status, activities];
}
