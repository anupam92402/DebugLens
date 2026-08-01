import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../data/debug_limits_store.dart';
import '../../domain/debug_limit.dart';

/// Prompts for a new cap for [limit] and applies it.
Future<void> showLimitEditDialog(BuildContext context, DebugLimit limit) {
  return showDialog<void>(
    context: context,
    builder: (_) => _LimitEditDialog(limit: limit),
  );
}

class _LimitEditDialog extends StatefulWidget {
  final DebugLimit limit;

  const _LimitEditDialog({required this.limit});

  @override
  State<_LimitEditDialog> createState() => _LimitEditDialogState();
}

class _LimitEditDialogState extends State<_LimitEditDialog> {
  /// Clamped on the way in: a limit stored before the bounds were last changed
  /// could otherwise sit outside the slider's range.
  late double _value = DebugLimits.instance
      .of(widget.limit)
      .clamp(DebugLimit.min, DebugLimit.max)
      .toDouble();

  int get _pending => _value.round();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DebugColors.surface,
      title: Text(
        DebugStrings.settingsLimitTitle(widget.limit.label),
        style: monoStyle(size: 14),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              '$_pending',
              style: monoStyle(size: 24, color: DebugColors.service),
            ),
          ),
          Slider(
            min: DebugLimit.min.toDouble(),
            max: DebugLimit.max.toDouble(),
            divisions: DebugLimit.divisions,
            value: _value,
            label: '$_pending',
            onChanged: (v) => setState(() => _value = v),
          ),
          // The ends of the track, so the range is readable without dragging.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${DebugLimit.min}',
                style: monoStyle(size: 11, color: DebugColors.textMuted),
              ),
              Text(
                '${DebugLimit.max}',
                style: monoStyle(size: 11, color: DebugColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            DebugStrings.settingsLimitDefault(widget.limit.fallback),
            style: monoStyle(size: 11, color: DebugColors.textMuted),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            DebugLimits.instance.reset(widget.limit);
            Navigator.of(context).pop();
          },
          child: const Text(DebugStrings.serviceResetLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(DebugStrings.commonCancel),
        ),
        TextButton(
          onPressed: () {
            DebugLimits.instance.set(widget.limit, _pending);
            Navigator.of(context).pop();
          },
          child: const Text(DebugStrings.serviceSave),
        ),
      ],
    );
  }
}
