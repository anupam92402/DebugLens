import 'package:connectivity_plus/connectivity_plus.dart';

import '../debug_strings.dart';

/// Human label for a connectivity transport, shared by the Network AppBar
/// indicator and the Device screen so the two can't drift apart.
///
/// `null` means "not read yet" — [Connectivity.checkConnectivity] is async, so
/// there is a frame before the first real value arrives.
String connectivityLabel(ConnectivityResult? result) => switch (result) {
  ConnectivityResult.wifi => DebugStrings.networkConnWifi,
  ConnectivityResult.mobile => DebugStrings.networkConnMobile,
  ConnectivityResult.ethernet => DebugStrings.networkConnEthernet,
  ConnectivityResult.vpn => DebugStrings.networkConnVpn,
  ConnectivityResult.bluetooth => DebugStrings.networkConnBluetooth,
  ConnectivityResult.other => DebugStrings.networkConnOther,
  ConnectivityResult.none => DebugStrings.networkConnOffline,
  null => DebugStrings.networkConnChecking,
};

/// The current transport, then every change.
///
/// [Connectivity.onConnectivityChanged] stays silent until something actually
/// changes, so a bare listen would read "checking" until the user toggled wifi
/// — the current value has to be fetched up front and prepended. That first
/// read is the only fetch; everything after it is pushed by the platform.
Stream<ConnectivityResult> connectivityStream() async* {
  yield await Connectivity().checkConnectivity();
  yield* Connectivity().onConnectivityChanged;
}
