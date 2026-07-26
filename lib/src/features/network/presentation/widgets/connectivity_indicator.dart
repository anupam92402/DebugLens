import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/util/connectivity_label.dart';

/// AppBar icon for the device's current connectivity transport (wifi /
/// mobile / ethernet / offline), updated live. Reports transport, not
/// internet reachability.
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
      message: connectivityLabel(_result),
      // Match an IconButton's 48px footprint so the AppBar actions are evenly
      // spaced (this indicator isn't tappable, so it's not an IconButton).
      child: SizedBox(width: 48, child: Icon(r.icon, color: r.color, size: 20)),
    );
  }

  /// Maps a `ConnectivityResult` to its icon and colour. The label comes from
  /// the shared `connectivityLabel`, so the Device screen shows the same words.
  static _IndicatorVisual _resolve(ConnectivityResult? r) {
    switch (r) {
      case ConnectivityResult.wifi:
        return const _IndicatorVisual(Icons.wifi, DebugColors.success);
      case ConnectivityResult.mobile:
        return const _IndicatorVisual(
          Icons.signal_cellular_alt,
          DebugColors.info,
        );
      case ConnectivityResult.ethernet:
        return const _IndicatorVisual(Icons.lan, DebugColors.info);
      case ConnectivityResult.vpn:
        return const _IndicatorVisual(Icons.vpn_lock, DebugColors.warning);
      case ConnectivityResult.bluetooth:
        return const _IndicatorVisual(Icons.bluetooth, DebugColors.info);
      case ConnectivityResult.other:
        return const _IndicatorVisual(Icons.device_hub, DebugColors.textMuted);
      case ConnectivityResult.none:
        return const _IndicatorVisual(Icons.signal_wifi_off, DebugColors.error);
      case null:
        return const _IndicatorVisual(
          Icons.help_outline,
          DebugColors.textMuted,
        );
    }
  }
}

/// Icon / colour pair returned by `_resolve`.
class _IndicatorVisual {
  final IconData icon;
  final Color color;

  const _IndicatorVisual(this.icon, this.color);
}
