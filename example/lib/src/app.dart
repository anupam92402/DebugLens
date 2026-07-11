import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/home/data/activity_repository.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/insights/data/insights_repository.dart';
import 'features/insights/presentation/cubit/insights_cubit.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/shell/presentation/cubit/shell_cubit.dart';
import 'features/shell/presentation/views/shell_screen.dart';

/// Root of the example app.
///
/// Provides every bloc/cubit above the [MaterialApp] so pushed routes
/// (notifications, settings) can read them too, and wires DebugLens in:
/// the navigator observer feeds the Navigation inspector and [DebugLens.wrap]
/// overlays the draggable bug bubble.
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ShellCubit()),
        BlocProvider(create: (_) => SettingsCubit()),
        BlocProvider(
          create: (_) =>
              HomeBloc(ActivityRepository())..add(const HomeStarted()),
        ),
        BlocProvider(
          create: (_) => InsightsCubit(InsightsRepository())..load(),
        ),
        BlocProvider(
          create: (_) => NotificationsCubit(NotificationRepository())..load(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return MaterialApp(
            title: 'DebugLens Example',
            debugShowCheckedModeBanner: false,
            navigatorObservers: [DebugLens.navigatorObserver],
            builder: (context, child) =>
                DebugLens.wrap(child ?? const SizedBox.shrink()),
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const ShellScreen(),
          );
        },
      ),
    );
  }
}
