import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/api_repository.dart';
import '../../../domain/post.dart';

part 'posts_event.dart';
part 'posts_state.dart';

/// View-model for the posts list: fetches posts through [ApiRepository].
class PostsBloc extends Bloc<PostsEvent, PostsState> {
  PostsBloc(this._repository) : super(const PostsState()) {
    on<PostsFetched>(_onFetched);
  }

  final ApiRepository _repository;

  Future<void> _onFetched(PostsFetched event, Emitter<PostsState> emit) async {
    emit(state.copyWith(status: PostsStatus.loading));
    try {
      final posts = await _repository.fetchPosts();
      emit(state.copyWith(status: PostsStatus.success, posts: posts));
    } catch (e) {
      emit(state.copyWith(status: PostsStatus.failure, error: '$e'));
    }
  }
}
