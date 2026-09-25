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
    _sub = connectivityStream().listen((value) {
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
  ///
  /// Matched on the enum's name for the same reason as `connectivityLabel`:
  /// the members differ across the `connectivity_plus` majors DebugLens
  /// supports.
  static _IndicatorVisual _resolve(ConnectivityResult? r) {
    switch (r?.name) {
      case null:
        return const _IndicatorVisual(
          Icons.help_outline,
          DebugColors.textMuted,
        );
      case 'wifi':
        return const _IndicatorVisual(Icons.wifi, DebugColors.success);
      case 'mobile':
        return const _IndicatorVisual(
          Icons.signal_cellular_alt,
          DebugColors.info,
        );
      case 'ethernet':
        return const _IndicatorVisual(Icons.lan, DebugColors.info);
      case 'vpn':
        return const _IndicatorVisual(Icons.vpn_lock, DebugColors.warning);
      case 'bluetooth':
        return const _IndicatorVisual(Icons.bluetooth, DebugColors.info);
      case 'satellite':
        return const _IndicatorVisual(Icons.satellite_alt, DebugColors.info);
      case 'none':
        return const _IndicatorVisual(Icons.signal_wifi_off, DebugColors.error);
      default:
        return const _IndicatorVisual(Icons.device_hub, DebugColors.textMuted);
    }
  }
}

/// Icon / colour pair returned by `_resolve`.
class _IndicatorVisual {
  final IconData icon;
  final Color color;

  const _IndicatorVisual(this.icon, this.color);
}
