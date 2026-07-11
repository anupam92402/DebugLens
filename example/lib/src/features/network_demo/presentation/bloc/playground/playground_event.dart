part of 'playground_bloc.dart';

sealed class PlaygroundEvent extends Equatable {
  const PlaygroundEvent();

  @override
  List<Object> get props => [];
}

final class ApiActionRun extends PlaygroundEvent {
  const ApiActionRun(this.action);

  final ApiAction action;

  @override
  List<Object> get props => [action];
}
