import 'package:debug_lens/debug_lens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/app.dart';
import 'src/core/di/service_locator.dart';
import 'src/core/notifications/notification_service.dart';
import 'src/core/storage/storage_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Feed every cubit/bloc in the app into the DebugLens Bloc inspector.
  Bloc.observer = DebugLensBlocObserver();
  setupLocator();

  // Real app storage (SharedPreferences + Drift), bridged to DebugLens.
  await setupStorage();

  // Local notifications — request permission up front.
  await sl<NotificationService>().init();

  runApp(const ExampleApp());
}
