import 'api_service.dart';
import '../domain/post.dart';

/// Maps [ApiService] responses to domain models. The bloc talks only to this,
/// never to Dio directly. Network/HTTP errors surface as the underlying
/// `DioException` for the bloc to catch.
class ApiRepository {
  ApiRepository(this._service);

  final ApiService _service;

  Future<List<Post>> fetchPosts() async {
    final res = await _service.getPosts();
    final data = (res.data as List<dynamic>);
    return data
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<String> fetchCatFact() async {
    final res = await _service.getCatFact();
    return (res.data as Map<String, dynamic>)['fact'] as String? ?? '';
  }

  Future<void> fetchMissingPost() => _service.getMissingPost();

  Future<Post> createPost() async {
    final res = await _service.createPost();
    return Post.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Post> updatePost() async {
    final res = await _service.updatePost();
    return Post.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deletePost() => _service.deletePost();
}
