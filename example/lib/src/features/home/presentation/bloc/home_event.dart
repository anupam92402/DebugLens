part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeActivityAdded extends HomeEvent {
  const HomeActivityAdded({required this.title, required this.category});

  final String title;
  final ActivityCategory category;

  @override
  List<Object> get props => [title, category];
}

final class HomeActivityToggled extends HomeEvent {
  const HomeActivityToggled(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

final class HomeActivityDeleted extends HomeEvent {
  const HomeActivityDeleted(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}
