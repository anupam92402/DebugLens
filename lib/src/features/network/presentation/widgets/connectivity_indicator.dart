import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';

/// AppBar icon showing the device's current connectivity transport —
/// wifi / mobile / ethernet / offline. Subscribes to
/// `Connectivity.onConnectivityChanged` for live updates and cancels in
/// dispose.
///
/// Note: reports *transport*, not *internet reachability*. A captive-portal
/// Wi-Fi still shows the green Wi-Fi icon — that's a `connectivity_plus`
/// limitation, not ours.
class ConnectivityIndicator extends StatefulWidget {
  const ConnectivityIndicator({super.key});

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator> {
  ConnectivityResult? _result;
  StreamSubscription<ConnectivityResult>? _sub;

  @override
  void initState() {
    super.initState();
    // connectivity_plus 4.x exposes single-value Future / Stream; v6+ uses
    // List<ConnectivityResult>. Sticking with 4.x to match the workspace.
    Connectivity().checkConnectivity().then((value) {
      if (mounted) setState(() => _result = value);
    });
    _sub = Connectivity().onConnectivityChanged.listen((value) {
      if (mounted) setState(() => _result = value);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _resolve(_result);
    return Tooltip(
      message: r.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Icon(r.icon, color: r.color, size: 20),
      ),
    );
  }

  /// Pure mapping from `ConnectivityResult` → icon/colour/label. Kept as a
  /// static method so it can be unit-tested without instantiating the
  /// widget.
  static _IndicatorVisual _resolve(ConnectivityResult? r) {
    switch (r) {
      case ConnectivityResult.wifi:
        return const _IndicatorVisual(
          Icons.wifi,
          DebugPalette.success,
          DebugStrings.networkConnWifi,
        );
      case ConnectivityResult.mobile:
        return const _IndicatorVisual(
          Icons.signal_cellular_alt,
          DebugPalette.info,
          DebugStrings.networkConnMobile,
        );
      case ConnectivityResult.ethernet:
        return const _IndicatorVisual(
          Icons.lan,
          DebugPalette.info,
          DebugStrings.networkConnEthernet,
        );
      case ConnectivityResult.vpn:
        return const _IndicatorVisual(
          Icons.vpn_lock,
          DebugPalette.warning,
          DebugStrings.networkConnVpn,
        );
      case ConnectivityResult.bluetooth:
        return const _IndicatorVisual(
          Icons.bluetooth,
          DebugPalette.info,
          DebugStrings.networkConnBluetooth,
        );
      case ConnectivityResult.other:
        return const _IndicatorVisual(
          Icons.device_hub,
          DebugPalette.textMuted,
          DebugStrings.networkConnOther,
        );
      case ConnectivityResult.none:
        return const _IndicatorVisual(
          Icons.signal_wifi_off,
          DebugPalette.error,
          DebugStrings.networkConnOffline,
        );
      case null:
        return const _IndicatorVisual(
          Icons.help_outline,
          DebugPalette.textMuted,
          DebugStrings.networkConnChecking,
        );
    }
  }
}

/// Small triple of icon / colour / tooltip — the only thing
/// `_resolve` actually returns, packaged for type safety.
class _IndicatorVisual {
  final IconData icon;
  final Color color;
  final String label;

  const _IndicatorVisual(this.icon, this.color, this.label);
}
