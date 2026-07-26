import 'package:flutter/foundation.dart';

import '../domain/config_editor.dart';
import '../domain/service_group.dart';

/// Generic, async view of one backend/SDK service, implemented by the host
/// using its own wrappers (Firebase, Amplify, LaunchDarkly, a REST client, …).
/// DebugLens calls [load] on demand from the Services screen and renders the
/// groups — it never imports any vendor package, so it stays generic.
///
/// **`extends` this, don't `implements` it** — only [name] is required; the
/// rest have working defaults that `implements` would force you to re-declare.
abstract class DebugLensService {
  /// Display name shown in the service list (e.g. 'Remote Config').
  String get name;

  /// Loads the service's current data as titled groups. Defaults to empty, so
  /// a service that only exposes an [editor] need not implement it.
  Future<List<DebugLensServiceGroup>> load() async => const [];

  /// Whether this service can clear its captured data. When true the service
  /// screen shows a delete action that calls [clear].
  bool get canClear => false;

  /// Clears the service's captured data. No-op unless [canClear] is true.
  Future<void> clear() async {}

  /// Optional editable-config capability (e.g. Remote Config overrides). When
  /// non-null the service screen renders a source toggle + editable rows.
  DebugLensConfigEditor? get editor => null;

  /// Optional signal that this service's data changed outside the inspector
  /// (a new analytics event, a crash recorded, a config fetch). When non-null
  /// the open service screen re-pulls on every notification, so the view stays
  /// live without the user leaving and re-entering.
  ///
  /// A `ValueNotifier`/`ChangeNotifier` you already own is the usual answer.
  Listenable? get changes => null;
}

/// Registry of host-provided services shown on the Services screen.
/// Static + global so the host can register once at startup.
class DebugLensServices {
  DebugLensServices._();

  static final List<DebugLensService> _services = <DebugLensService>[];

  /// Notifies listeners (the Services screen) whenever the registry changes,
  /// so a service registered *after* the screen is built still shows up. The
  /// value is an unmodifiable snapshot in insertion order.
  static final ValueNotifier<List<DebugLensService>> listenable =
      ValueNotifier<List<DebugLensService>>(List.unmodifiable(_services));

  /// Registered services, in insertion order. Returns an unmodifiable view so
  /// callers can't mutate the registry behind [register]'s back.
  static List<DebugLensService> get services => List.unmodifiable(_services);

  /// Adds [service], replacing any existing one with the same name so repeated
  /// registration stays idempotent.
  static void register(DebugLensService service) {
    _services.removeWhere((s) => s.name == service.name);
    _services.add(service);
    listenable.value = List.unmodifiable(_services);
  }
}
