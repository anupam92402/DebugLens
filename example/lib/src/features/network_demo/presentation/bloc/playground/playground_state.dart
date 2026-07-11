part of 'playground_bloc.dart';

enum ActionPhase { idle, loading, success, error }

final class ActionResult extends Equatable {
  const ActionResult({this.phase = ActionPhase.idle, this.detail = ''});

  final ActionPhase phase;
  final String detail;

  @override
  List<Object> get props => [phase, detail];
}

final class PlaygroundState extends Equatable {
  const PlaygroundState([this.results = const {}]);

  final Map<ApiAction, ActionResult> results;

  ActionResult resultFor(ApiAction action) =>
      results[action] ?? const ActionResult();

  PlaygroundState updated(ApiAction action, ActionResult result) =>
      PlaygroundState({...results, action: result});

  @override
  List<Object> get props => [results];
}
