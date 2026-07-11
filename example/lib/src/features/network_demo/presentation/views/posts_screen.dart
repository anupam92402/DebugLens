import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/navigation/tab_routes.dart';
import '../bloc/posts/posts_bloc.dart';
import '../widgets/post_tile.dart';

/// Posts list built from the GET /posts response. Tapping a post opens its
/// detail screen with the already-fetched [Post] (no refetch).
class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PostsBloc>()..add(const PostsFetched()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Posts')),
        body: BlocBuilder<PostsBloc, PostsState>(
          builder: (context, state) {
            switch (state.status) {
              case PostsStatus.initial:
              case PostsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case PostsStatus.failure:
                return _Failure(
                  error: state.error,
                  onRetry: () =>
                      context.read<PostsBloc>().add(const PostsFetched()),
                );
              case PostsStatus.success:
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final post = state.posts[i];
                    return PostTile(
                      post: post,
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(TabRoutes.postDetail, arguments: post),
                    );
                  },
                );
            }
          },
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40),
            const SizedBox(height: 12),
            Text('Couldn\'t load posts', textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
