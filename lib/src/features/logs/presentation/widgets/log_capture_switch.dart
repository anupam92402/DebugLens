import 'package:flutter/material.dart';

import '../../data/debug_lens_logger.dart';
import '../../domain/log_origin.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// One origin row — its name, the integration behind it, and the switch. The
/// switch position is the state, so the row doesn't spell it out again.
class LogCaptureSwitch extends StatelessWidget {
  final DebugLogOrigin origin;
  final DebugLensLogger logger;

  const LogCaptureSwitch({
    super.key,
    required this.origin,
    required this.logger,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: logger.isCapturing(origin),
      title: Text(origin.label, style: monoStyle(size: 13)),
      subtitle: Text(
        origin.description,
        style: monoStyle(size: 11, color: DebugColors.textMuted),
      ),
      onChanged: (next) => logger.setCapturing(origin, next),
    );
  }
}
