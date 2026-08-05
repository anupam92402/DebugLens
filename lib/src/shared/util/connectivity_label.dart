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
  ConnectivityResult.satellite => DebugStrings.networkConnSatellite,
  ConnectivityResult.other => DebugStrings.networkConnOther,
  ConnectivityResult.none => DebugStrings.networkConnOffline,
  null => DebugStrings.networkConnChecking,
};

ConnectivityResult _primary(List<ConnectivityResult> results) => results
    .firstWhere((r) => r != ConnectivityResult.none, orElse: () => ConnectivityResult.none);

Stream<ConnectivityResult> connectivityStream() async* {
  yield _primary(await Connectivity().checkConnectivity());
  yield* Connectivity().onConnectivityChanged.map(_primary);
}
