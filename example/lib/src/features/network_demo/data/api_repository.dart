import 'package:debug_lens/debug_lens.dart';

import 'api_service.dart';
import '../domain/post.dart';

/// Maps [ApiService] responses to domain models. The bloc talks only to this,
/// never to Dio directly. Network/HTTP errors surface as the underlying
/// `DioException` for the bloc to catch.
class ApiRepository {
  ApiRepository(this._service);

  final ApiService _service;

  /// The Dio interceptor already logs the HTTP line; these log the *domain*
  /// outcome, which is what you actually scan the feed for.
  Future<List<Post>> fetchPosts() async {
    final res = await _service.getPosts();
    final data = (res.data as List<dynamic>);
    final posts = data
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    DebugLensLogger().d('Fetched ${posts.length} posts', name: 'api');
    return posts;
  }

  Future<String> fetchCatFact() async {
    final res = await _service.getCatFact();
    return (res.data as Map<String, dynamic>)['fact'] as String? ?? '';
  }

  Future<void> fetchMissingPost() => _service.getMissingPost();

  Future<Post> createPost() async {
    final res = await _service.createPost();
    final post = Post.fromJson(res.data as Map<String, dynamic>);
    DebugLensLogger().i('Created post #${post.id}', name: 'api');
    return post;
  }

  Future<Post> updatePost() async {
    final res = await _service.updatePost();
    final post = Post.fromJson(res.data as Map<String, dynamic>);
    DebugLensLogger().i('Updated post #${post.id}', name: 'api');
    return post;
  }

  Future<void> deletePost() => _service.deletePost();
}
