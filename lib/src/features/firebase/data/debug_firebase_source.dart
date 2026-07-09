import 'package:flutter/foundation.dart';

import '../domain/info_group.dart';

/// Generic, read-only, async view of one Firebase service, implemented by the
/// host using its own Firebase wrappers. DebugLens calls [load] on demand from
/// the Firebase screen and renders the groups — it never imports any Firebase
/// package, so it stays generic.
abstract class DebugLensFirebaseService {
  /// Display name shown in the service list (e.g. 'Remote Config').
  String get name;

  /// Loads the service's current data as titled info groups.
  Future<List<DebugLensInfoGroup>> load();
}

/// Registry of host-provided Firebase services shown on the Firebase screen.
/// Static + global so the host can register once at startup.
class DebugLensFirebase {
  DebugLensFirebase._();

  static final List<DebugLensFirebaseService> _services =
      <DebugLensFirebaseService>[];

  /// Notifies listeners (the Firebase screen) whenever the registry changes,
  /// so a service registered *after* the screen is built still shows up. The
  /// value is an unmodifiable snapshot in insertion order.
  static final ValueNotifier<List<DebugLensFirebaseService>> listenable =
      ValueNotifier<List<DebugLensFirebaseService>>(
        List.unmodifiable(_services),
      );

  /// Registered services, in insertion order. Returns an unmodifiable view so
  /// callers can't mutate the registry behind [register]'s back.
  static List<DebugLensFirebaseService> get services =>
      List.unmodifiable(_services);

  /// Adds [service], replacing any existing one with the same name so repeated
  /// registration stays idempotent.
  static void register(DebugLensFirebaseService service) {
    _services.removeWhere((s) => s.name == service.name);
    _services.add(service);
    listenable.value = List.unmodifiable(_services);
  }
}
