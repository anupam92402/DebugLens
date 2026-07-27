import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../domain/health_report.dart';

/// One failure in a health report — a crash or an error log — expanding to its
/// detail and stack trace.
class HealthEntryTile extends StatelessWidget {
  final HealthEntry entry;

  const HealthEntryTile({super.key, required this.entry});

  bool get _isCrash => entry.kind == HealthEntryKind.crash;

  /// Crashes read louder than error logs: one took the widget down, the other
  /// was caught and reported.
  Color get _tone => _isCrash ? DebugColors.error : DebugColors.warning;

  String get _kindLabel =>
      _isCrash ? DebugStrings.healthKindCrash : DebugStrings.healthKindLog;

  @override
  Widget build(BuildContext context) {
    final hasBody = entry.detail != null || entry.stackTrace != null;
    final subtitle = Text(
      '${ClockFormat.clock(entry.time)}'
      '${entry.subtitle == null ? '' : ' · ${entry.subtitle}'}',
      style: monoStyle(size: 11, color: DebugColors.textMuted),
    );
    final title = Row(
      children: [
        StatusChip(_kindLabel, color: _tone),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            entry.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: monoStyle(size: 13),
          ),
        ),
      ],
    );

    // Nothing behind it — render a flat row rather than an expander that opens
    // onto an empty box.
    if (!hasBody) {
      return ListTile(title: title, subtitle: subtitle);
    }
    return ExpansionTile(
      title: title,
      subtitle: subtitle,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        if (entry.detail != null) CodeBlock(entry.detail!, color: _tone),
        if (entry.detail != null && entry.stackTrace != null)
          const SizedBox(height: 8),
        if (entry.stackTrace != null) CodeBlock(entry.stackTrace!),
      ],
    );
  }
}
