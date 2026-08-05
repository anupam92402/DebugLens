import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/app_providers.dart';
import 'src/core/app_navigator.dart';
import 'src/core/backend_bootstrap.dart';
import 'src/core/error_routing.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/settings/presentation/cubit/settings_cubit.dart';
import 'src/features/shell/presentation/views/shell_screen.dart';

void main() => _bootstrap();

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Routes Flutter's error channels into the Logs feed.
  logErrorRouting();

  // Swaps Flutter's red error box for DebugLens's shareable one.
  ErrorWidget.builder = (details) => CustomErrorScreen(details: details);

  // Master switch — on in every mode here so a release build stays inspectable.
  DebugLens.debugLensEnabled = !kReleaseMode;

  // Opens straight into the full panel instead of the default tester role.
  DebugLens.initialRole = DebugRole.developer;

  // What a tester sees on a fresh install; editable later from Settings.
  DebugLens.initialTesterAccess = {
    DebugScreen.network,
    DebugScreen.logs,
    DebugScreen.device,
  };

  // Echo to console only in debug builds.
  DebugLensLogger().printToConsole = kDebugMode;

  // Feed every cubit/bloc in the app into the DebugLens Bloc inspector.
  Bloc.observer = DebugLensBlocObserver();

  // This demo's own DI + mock backend + storage + notifications.
  await initializeDemoBackend();

  runApp(const ExampleApp());
}

/// Root of the example app.
///
/// Wires DebugLens onto the [MaterialApp]: the navigator observer feeds the
/// Navigation inspector and [DebugLens.wrap] overlays the draggable bug
/// bubble. Everything else this demo needs comes from [AppProviders].
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return MaterialApp(
            title: 'DebugLens Example',
            debugShowCheckedModeBanner: false,
            navigatorKey: appNavigatorKey,
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
