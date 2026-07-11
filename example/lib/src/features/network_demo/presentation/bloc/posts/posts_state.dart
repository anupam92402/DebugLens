part of 'posts_bloc.dart';

enum PostsStatus { initial, loading, success, failure }

final class PostsState extends Equatable {
  const PostsState({
    this.status = PostsStatus.initial,
    this.posts = const [],
    this.error = '',
  });

  final PostsStatus status;
  final List<Post> posts;
  final String error;

  PostsState copyWith({
    PostsStatus? status,
    List<Post>? posts,
    String? error,
  }) => PostsState(
    status: status ?? this.status,
    posts: posts ?? this.posts,
    error: error ?? this.error,
  );

  @override
  List<Object> get props => [status, posts, error];
}
