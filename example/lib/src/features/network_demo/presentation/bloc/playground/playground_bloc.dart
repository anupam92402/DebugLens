import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/firebase/mock_firebase.dart';
import '../../../data/api_repository.dart';
import '../../../domain/api_action.dart';

part 'playground_event.dart';
part 'playground_state.dart';

/// View-model for the playground's inline quick calls. Runs one [ApiAction]
/// per event and tracks its outcome so each tile updates independently.
class PlaygroundBloc extends Bloc<PlaygroundEvent, PlaygroundState> {
  PlaygroundBloc(this._repository) : super(const PlaygroundState()) {
    on<ApiActionRun>(_onRun);
  }

  final ApiRepository _repository;

  Future<void> _onRun(ApiActionRun event, Emitter<PlaygroundState> emit) async {
    final action = event.action;
    emit(state.updated(action, const ActionResult(phase: ActionPhase.loading)));
    MockFirebase.analytics.logEvent(
      'api_action',
      parameters: {'action': action.name},
    );
    try {
      // Time each call as a mock-Firebase performance trace (one per action).
      final detail = await MockFirebase.performance.trace(
        'api_${action.name}',
        () => _runAndDescribe(action),
      );
      emit(
        state.updated(
          action,
          ActionResult(phase: ActionPhase.success, detail: detail),
        ),
      );
    } on DioException catch (e, stack) {
      final detail = e.response?.statusCode != null
          ? 'HTTP ${e.response!.statusCode}'
          : (e.message ?? 'Request failed');
      // Report the failed call as a mock-Firebase non-fatal.
      MockFirebase.crashlytics.recordError(
        e,
        stack,
        reason: 'API ${action.name} failed ($detail)',
      );
      emit(
        state.updated(
          action,
          ActionResult(phase: ActionPhase.error, detail: detail),
        ),
      );
    }
  }

  Future<String> _runAndDescribe(ApiAction action) async {
    switch (action) {
      case ApiAction.catFact:
        return _repository.fetchCatFact();
      case ApiAction.createPost:
        final post = await _repository.createPost();
        return 'Created #${post.id}';
      case ApiAction.updatePost:
        final post = await _repository.updatePost();
        return 'Updated #${post.id}';
      case ApiAction.deletePost:
        await _repository.deletePost();
        return 'Deleted';
      case ApiAction.missingPost:
        await _repository.fetchMissingPost();
        return 'OK';
    }
  }
}
