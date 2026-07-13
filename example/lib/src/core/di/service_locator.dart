import 'package:debug_lens/debug_lens.dart';
import 'package:get_it/get_it.dart';

import '../../features/network_demo/data/api_repository.dart';
import '../../features/network_demo/data/api_service.dart';
import '../../features/network_demo/presentation/bloc/playground/playground_bloc.dart';
import '../../features/network_demo/presentation/bloc/posts/posts_bloc.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_cubit.dart';
import '../notifications/notification_service.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Registers the app's dependencies. Idempotent so tests can call it
/// repeatedly without a double-registration error.
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

  // On-device local notifications.
  sl.registerLazySingleton<NotificationService>(NotificationService.new);

  // Language: one shared cubit, and a bridge feeding the active strings to the
  // DebugLens Locale inspector (read on demand — no copy kept).
  sl.registerLazySingleton<LocaleCubit>(LocaleCubit.new);
  DebugLens.localeSource = () {
    final lang = sl<LocaleCubit>().state;
    return DebugLensLocaleData(
      entries: AppStrings.data[lang]!,
      label: AppStrings.label(lang),
    );
  };
}
