import '../domain/locale_data.dart';

/// Pull-based provider of the app's locale strings, registered by the host via
/// `DebugLens.localeSource`. Called on demand; no copy kept.
typedef DebugLensLocaleSource = DebugLensLocaleData Function();

/// Holds the host-registered [DebugLensLocaleSource]. Static + global so the
/// host can wire it once at startup, mirroring how `Bloc.observer` is set.
class DebugLensLocale {
  DebugLensLocale._();

  /// The current source, or `null` when the host hasn't registered one (the
  /// Locale screen then shows its empty state).
  static DebugLensLocaleSource? source;
}
