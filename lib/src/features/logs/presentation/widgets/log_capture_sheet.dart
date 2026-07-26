import 'package:flutter/material.dart';

import '../../data/debug_lens_logger.dart';
import '../../domain/log_origin.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/glass.dart';

/// Bottom sheet listing DebugLens's own log producers with a switch each, so
/// the user can silence a noisy one mid-session.
///
/// Switching one off only stops *new* records; what is already in the feed
/// stays there and in anything shared from it. Rebuilds off the logger, which
/// notifies whenever a toggle changes.
class LogCaptureSheet extends StatelessWidget {
  const LogCaptureSheet({super.key});

  /// Opens the sheet over [context]'s navigator.
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const LogCaptureSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final logger = DebugLensLogger.instance;
    return GlassSurface(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DebugStrings.logsCaptureTitle,
                style: monoStyle(size: 15, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                DebugStrings.logsCaptureHint,
                style: monoStyle(size: 11, color: DebugColors.textMuted),
              ),
              const SizedBox(height: 4),
              ListenableBuilder(
                listenable: logger,
                builder: (_, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final origin in DebugLogOrigin.values)
                      _CaptureSwitch(origin: origin, logger: logger),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One origin row — its name, the integration behind it, and the switch. The
/// switch position is the state, so the row doesn't spell it out again.
class _CaptureSwitch extends StatelessWidget {
  final DebugLogOrigin origin;
  final DebugLensLogger logger;

  const _CaptureSwitch({required this.origin, required this.logger});

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
