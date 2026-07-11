import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/activity_repository.dart';
import '../../domain/activity.dart';

part 'home_event.dart';
part 'home_state.dart';

/// View-model for the Home tab: loads activities and handles add/toggle.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._repository) : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeActivityAdded>(_onActivityAdded);
    on<HomeActivityToggled>(_onActivityToggled);
    on<HomeActivityDeleted>(_onActivityDeleted);
  }

  final ActivityRepository _repository;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    final activities = await _repository.fetchActivities();
    emit(state.copyWith(status: HomeStatus.ready, activities: activities));
  }

  void _onActivityAdded(HomeActivityAdded event, Emitter<HomeState> emit) {
    final activity = Activity(
      id: 'a${DateTime.now().microsecondsSinceEpoch}',
      title: event.title,
      category: event.category,
      timeLabel: 'Just now',
    );
    emit(state.copyWith(activities: [activity, ...state.activities]));
  }

  void _onActivityToggled(HomeActivityToggled event, Emitter<HomeState> emit) {
    final activities = [
      for (final activity in state.activities)
        if (activity.id == event.id)
          activity.copyWith(isDone: !activity.isDone)
        else
          activity,
    ];
    emit(state.copyWith(activities: activities));
  }

  void _onActivityDeleted(HomeActivityDeleted event, Emitter<HomeState> emit) {
    emit(
      state.copyWith(
        activities: state.activities
            .where((activity) => activity.id != event.id)
            .toList(),
      ),
    );
  }
}
