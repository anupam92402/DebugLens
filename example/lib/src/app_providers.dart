import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'core/l10n/locale_cubit.dart';
import 'features/home/data/activity_repository.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/shell/presentation/cubit/shell_cubit.dart';

/// Every bloc/cubit the demo needs above its [MaterialApp], so pushed routes
/// (notifications, settings) can read them too. Unrelated to DebugLens itself
/// — this is just how this particular app is wired.
class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ShellCubit()),
        BlocProvider(create: (_) => SettingsCubit()),
        BlocProvider.value(value: sl<LocaleCubit>()),
        BlocProvider(
          create: (_) =>
              HomeBloc(ActivityRepository())..add(const HomeStarted()),
        ),
        BlocProvider(
          create: (_) => NotificationsCubit(NotificationRepository())..load(),
        ),
      ],
      child: child,
    );
  }
}
