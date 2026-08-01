import '../../../shared/debug_constants.dart';
import '../../../shared/debug_strings.dart';

/// A DebugLens-provided producer of log records, toggleable at runtime from
/// the Logs screen's capture sheet.
///
/// These are the sources DebugLens itself writes into the Logs feed. Records
/// the host emits through `DebugLensLogger().i/d/e` have no origin and
/// are always captured — the host controls those at the call site.
///
/// Muting an origin stops *new* records from it; rows already in the buffer
/// stay visible and shareable.
enum DebugLogOrigin {
  network,
  bloc,
  navigation,
  notifications,
  services,
  storage;

  /// Name shown in the capture sheet.
  String get label => switch (this) {
    DebugLogOrigin.network => DebugStrings.logsOriginNetwork,
    DebugLogOrigin.bloc => DebugStrings.logsOriginBloc,
    DebugLogOrigin.navigation => DebugStrings.logsOriginNavigation,
    DebugLogOrigin.notifications => DebugStrings.logsOriginNotifications,
    DebugLogOrigin.services => DebugStrings.logsOriginServices,
    DebugLogOrigin.storage => DebugStrings.logsOriginStorage,
  };

  /// SharedPreferences key holding this origin's capture switch, so the user's
  /// choice survives a restart.
  String get prefsKey => '${DebugConstants.logCapturePrefsKeyPrefix}$name';

  /// Which DebugLens integration feeds this origin.
  String get description => switch (this) {
    DebugLogOrigin.network => DebugStrings.logsOriginNetworkHint,
    DebugLogOrigin.bloc => DebugStrings.logsOriginBlocHint,
    DebugLogOrigin.navigation => DebugStrings.logsOriginNavigationHint,
    DebugLogOrigin.notifications => DebugStrings.logsOriginNotificationsHint,
    DebugLogOrigin.services => DebugStrings.logsOriginServicesHint,
    DebugLogOrigin.storage => DebugStrings.logsOriginStorageHint,
  };
}
