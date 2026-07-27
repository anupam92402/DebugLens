import 'package:flutter/material.dart';

import '../../../../core/debug_store.dart';
import '../../domain/api_call_stat.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_bottom_sheet.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/glass.dart';
import 'api_call_row.dart';

/// Bottom sheet listing every retained call to one endpoint, newest at the top.
///
/// Each row carries its timestamp plus the gap since the call below it, so the
/// spacing of a polling loop or a burst of retries reads straight off the list.
/// The bottom row is the oldest retained call and has nothing to compare
/// against, so it shows a timestamp only.
///
/// Listens to [DebugStore] so calls arriving while the sheet is open appear at
/// the top — the stat is mutated in place, so a rebuild re-reads it.
class ApiCallsSheet extends StatelessWidget {
  final ApiCallStat stat;

  const ApiCallsSheet({super.key, required this.stat});

  /// Opens the sheet over [context]'s navigator.
  static Future<void> show(BuildContext context, ApiCallStat stat) =>
      showDebugBottomSheet<void>(
        context,
        builder: (_) => ApiCallsSheet(stat: stat),
      );

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: DebugStore.instance,
          builder: (context, _) {
            /// Newest first — the store keeps them oldest first.
            final times = stat.callTimes.reversed.toList(growable: false);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(times.length),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: times.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: DebugColors.border),
                    itemBuilder: (_, i) {
                      /// The row below is the previous (older) call. The last
                      /// row has none — it is the first call recorded here.
                      final previous = i + 1 < times.length
                          ? times[i + 1]
                          : null;
                      return ApiCallRow(
                        number: times.length - i,
                        at: times[i],
                        sincePrevious: previous == null
                            ? null
                            : times[i].difference(previous),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Endpoint identity plus how many calls the list is showing.
  Widget _header(int shown) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(stat.methodLabel, color: toneForMethod(stat.method)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stat.path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: monoStyle(size: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stat.isTrimmed
                ? DebugStrings.networkCallsTrimmed(shown, stat.total)
                : '${stat.total} ${stat.total == 1 ? DebugStrings.networkCall : DebugStrings.networkCalls}',
            style: monoStyle(size: 11, color: DebugColors.textMuted),
          ),
        ],
      ),
    );
  }
}
