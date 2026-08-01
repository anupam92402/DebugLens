import 'package:connectivity_plus/connectivity_plus.dart';

import '../debug_strings.dart';

/// Human label for a connectivity transport, shared by the Network AppBar
/// indicator and the Device screen so the two can't drift apart.
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
Stream<ConnectivityResult> connectivityStream() async* {
  yield await Connectivity().checkConnectivity();
  yield* Connectivity().onConnectivityChanged;
}
