import 'package:debug_lens/debug_lens.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/service_locator.dart';
import 'app_database.dart';
import 'drift_debug_lens_adapter.dart';
import 'prefs_bridge.dart';

/// Opens the app's real storage (SharedPreferences + Drift DB), seeds demo
/// data, registers both as get_it singletons, and hands DebugLens a
/// read-only bridge to each. Call once, before `runApp`.
Future<void> setupStorage() async {
  final GetIt locator = sl;

  final prefs = await SharedPreferences.getInstance();
  await PrefsBridge.seedIfEmpty(prefs);
  if (!locator.isRegistered<SharedPreferences>()) {
    locator.registerSingleton<SharedPreferences>(prefs);
  }
  DebugLens.sharedPrefsSource = () => PrefsBridge.snapshot(prefs);

  final db = AppDatabase();
  await db.seedIfEmpty();
  if (!locator.isRegistered<AppDatabase>()) {
    locator.registerSingleton<AppDatabase>(db);
  }
  DebugLens.registerDatabase(DriftDebugLensDatabase(db));
}
