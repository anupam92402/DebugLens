import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../data/health_log_share.dart';
import '../../domain/health_report.dart';
import '../widgets/health_entry_tile.dart';

/// What a health check found: every crash and error log recorded between the
/// start and stop taps, newest first, with the whole thing shareable.
class HealthReportScreen extends StatelessWidget {
  final HealthReport report;

  const HealthReportScreen({super.key, required this.report});

  Future<void> _share(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return HealthLogShare.share(
      report,
      origin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DebugStrings.healthTitleNumbered(report.number)),
        actions: [
          IconButton(
            tooltip: DebugStrings.healthShareTooltip,
            icon: const Icon(Icons.share),
            onPressed: () => _share(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _header(),
          const Divider(height: 1, color: DebugColors.border),
          Expanded(
            child: report.isClean
                ? const EmptyState(
                    icon: Icons.check_circle_outline,
                    message: DebugStrings.healthClean,
                  )
                : ListView.separated(
                    itemCount: report.entries.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: DebugColors.border),
                    itemBuilder: (_, i) =>
                        HealthEntryTile(entry: report.entries[i]),
                  ),
          ),
        ],
      ),
    );
  }

  /// The window that was watched, and the tally inside it.
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DebugStrings.healthWindow(
              ClockFormat.clock(report.startedAt),
              ClockFormat.clock(report.stoppedAt),
              ClockFormat.gap(report.duration),
            ),
            style: monoStyle(size: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              StatusChip(
                DebugStrings.healthCrashCount(report.crashCount),
                color: report.crashCount == 0
                    ? DebugColors.textMuted
                    : DebugColors.error,
              ),
              const SizedBox(width: 8),
              StatusChip(
                DebugStrings.healthLogCount(report.logCount),
                color: report.logCount == 0
                    ? DebugColors.textMuted
                    : DebugColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
