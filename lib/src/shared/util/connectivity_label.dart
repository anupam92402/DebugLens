import 'package:connectivity_plus/connectivity_plus.dart';

import '../debug_strings.dart';

/// Human label for a connectivity transport, shared by the Network AppBar
/// indicator and the Device screen so the two can't drift apart.
///
/// Matched on the enum's *name* rather than its constants. DebugLens supports a
/// range of `connectivity_plus` majors, and the enum has grown across them
/// (`satellite` arrived in v5), so naming a constant here would fail to compile
/// against the older majors a host app may still be on. Anything unrecognised
/// reads as "Other".
String connectivityLabel(ConnectivityResult? result) => switch (result?.name) {
  null => DebugStrings.networkConnChecking,
  'wifi' => DebugStrings.networkConnWifi,
  'mobile' => DebugStrings.networkConnMobile,
  'ethernet' => DebugStrings.networkConnEthernet,
  'vpn' => DebugStrings.networkConnVpn,
  'bluetooth' => DebugStrings.networkConnBluetooth,
  'satellite' => DebugStrings.networkConnSatellite,
  'none' => DebugStrings.networkConnOffline,
  _ => DebugStrings.networkConnOther,
};

/// The transport in force, from whichever shape the installed plugin reports.
///
/// `connectivity_plus` v4 hands back a single [ConnectivityResult]; v5 and
/// later hand back a list, because a device can be on several transports at
/// once. Both are accepted so the package resolves in either kind of host app.
ConnectivityResult _primary(Object? raw) {
  if (raw is ConnectivityResult) return raw;
  if (raw is List) {
    for (final entry in raw) {
      if (entry is ConnectivityResult && entry != ConnectivityResult.none) {
        return entry;
      }
    }
  }
  return ConnectivityResult.none;
}

/// The current transport, then every change.
Stream<ConnectivityResult> connectivityStream() async* {
  final connectivity = Connectivity();
  final dynamic current = await connectivity.checkConnectivity();
  yield _primary(current);
  final Stream<dynamic> changes = connectivity.onConnectivityChanged;
  yield* changes.map(_primary);
}
