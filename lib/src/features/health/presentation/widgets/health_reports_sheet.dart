import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_bottom_sheet.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/glass.dart';
import '../../../../shared/widgets/sequence_badge.dart';
import '../../../../shell/debug_routes.dart';
import '../../data/health_check_store.dart';

/// Bottom sheet listing this session's finished health checks, newest first.
/// Tapping one reopens its report.
class HealthReportsSheet extends StatelessWidget {
  const HealthReportsSheet({super.key});

  static Future<void> show(BuildContext context) => showDebugBottomSheet<void>(
    context,
    builder: (_) => const HealthReportsSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final reports = HealthCheckStore.instance.reports;
    return GlassSurface(
      squareBottom: true,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DebugStrings.healthPreviousTitle,
                    style: monoStyle(size: 14),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                itemCount: reports.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: DebugColors.border),
                itemBuilder: (_, i) {
                  final report = reports[i];
                  return ListTile(
                    dense: true,
                    leading: SequenceBadge(
                      DebugStrings.healthNumber(report.number),
                    ),
                    title: Row(
                      children: [
                        // Clean or not, at a glance, without costing the badge
                        // its slot.
                        Icon(
                          report.isClean
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          size: 14,
                          color: report.isClean
                              ? DebugColors.success
                              : DebugColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            DebugStrings.healthWindow(
                              ClockFormat.clock(report.startedAt),
                              ClockFormat.clock(report.stoppedAt),
                              ClockFormat.gap(report.duration),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: monoStyle(size: 12),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${DebugStrings.healthCrashCount(report.crashCount)} · '
                      '${DebugStrings.healthLogCount(report.logCount)}',
                      style: monoStyle(size: 11, color: DebugColors.textMuted),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      // Grabbed before popping — the sheet's own context is
                      // gone by the time the push runs, but the Navigator it
                      // belongs to is the panel's and outlives it.
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.pushNamed(
                        DebugRoutes.healthReport,
                        arguments: report,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
