import '../domain/locale_data.dart';

/// Pull-based provider of the app's locale strings.
///
/// DebugLens calls this each time the Locale screen builds and displays the
/// result; it deliberately keeps no copy. Register it from the host once the
/// lang data is available (e.g. after `WeLangBloc` emits `WeLangLoadedState`):
///
/// ```dart
/// DebugLens.localeSource = () => DebugLensLocaleData(
///       entries: weLangBloc.currentLangMap, // nested {prefix: {key: value}}
///       label: AppLocale.currentLabel,
///     );
/// ```
typedef DebugLensLocaleSource = DebugLensLocaleData Function();

/// Holds the host-registered [DebugLensLocaleSource]. Static + global so the
/// host can wire it once at startup, mirroring how `Bloc.observer` is set.
class DebugLensLocale {
  DebugLensLocale._();

  /// The current source, or `null` when the host hasn't registered one (the
  /// Locale screen then shows its empty state).
  static DebugLensLocaleSource? source;
}
