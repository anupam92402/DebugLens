import 'package:get_it/get_it.dart';

import '../../features/network_demo/data/api_repository.dart';
import '../../features/network_demo/data/api_service.dart';
import '../../features/network_demo/presentation/bloc/playground/playground_bloc.dart';
import '../../features/network_demo/presentation/bloc/posts/posts_bloc.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Registers the API playground's dependencies. Idempotent so tests can call
/// it repeatedly without a double-registration error.
void setupLocator() {
  if (sl.isRegistered<ApiService>()) return;

  // Data layer as lazy singletons — one Dio/interceptor for the whole session.
  sl.registerLazySingleton<ApiService>(ApiService.new);
  sl.registerLazySingleton<ApiRepository>(
    () => ApiRepository(sl<ApiService>()),
  );

  // Blocs as factories — a fresh instance per screen.
  sl.registerFactory<PostsBloc>(() => PostsBloc(sl<ApiRepository>()));
  sl.registerFactory<PlaygroundBloc>(() => PlaygroundBloc(sl<ApiRepository>()));
}
