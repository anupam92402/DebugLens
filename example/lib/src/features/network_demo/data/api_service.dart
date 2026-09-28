import 'package:debug_lens/debug_lens.dart';
import 'package:dio/dio.dart';

/// Remote data source for the playground. Owns a Dio instance carrying
/// [DebugLensDioInterceptor], so every call is captured by the Network
/// inspector. Returns raw [Response]s — mapping to models is the repository's
/// job.
class ApiService {
  ApiService() : _dio = Dio() {
    _dio.interceptors.add(DebugLensDioInterceptor());
  }

  final Dio _dio;

  static const _jsonPlaceholder = 'https://jsonplaceholder.typicode.com';

  /// Echo server that accepts any method and returns what it received.
  static const _httpbingo = 'https://httpbingo.org';

  Future<Response<dynamic>> getPosts() => _dio.get('$_jsonPlaceholder/posts');

  Future<Response<dynamic>> getCatFact() =>
      _dio.get('https://catfact.ninja/fact');

  Future<Response<dynamic>> getMissingPost() =>
      _dio.get('$_jsonPlaceholder/posts/999999');

  Future<Response<dynamic>> createPost() => _dio.post(
    '$_jsonPlaceholder/posts',
    data: {'title': 'DebugLens', 'body': 'hello', 'userId': 1},
  );

  Future<Response<dynamic>> updatePost() => _dio.put(
    '$_jsonPlaceholder/posts/1',
    data: {'id': 1, 'title': 'updated', 'body': 'world', 'userId': 1},
  );

  Future<Response<dynamic>> deletePost() =>
      _dio.delete('$_jsonPlaceholder/posts/1');

  /// An HTTP QUERY request (RFC 10008): a safe, idempotent read that carries
  /// its filter in the body. `dio.request` with the method name, since
  /// `dio.query()` only exists in newer Dio releases.
  Future<Response<dynamic>> searchPosts() => _dio.request(
    '$_httpbingo/anything/posts/search',
    data: {
      'filter': {'userId': 1, 'title': 'debug'},
      'limit': 5,
    },
    options: Options(method: 'QUERY', contentType: Headers.jsonContentType),
  );
}
