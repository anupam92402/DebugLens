import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/network_entry.dart';
import '../../../util/network_serializer.dart';
import '../../theme/debug_theme.dart';
import '../debug_toast.dart';
import '../debug_widgets.dart';

/// Single row in the Network list screen.
///
/// Affordances:
///   - tapping the row body → navigate to detail (handled by [onTap])
///   - long-pressing the row → copy cURL + response, open share
///   - swiping the row left or right → same copy + share (green "Copy cURL"
///     background, then the row snaps back — nothing is removed)
class NetworkTile extends StatelessWidget {
  final NetworkEntry entry;
  final VoidCallback onTap;

  const NetworkTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  /// Builds the payload + drops it into the system share sheet. The clipboard
  /// copy is kept so users can paste even if they dismiss the share sheet.
  Future<void> _copyAndShare(BuildContext context) async {
    final text = NetworkSerializer.formatCurlPlusResponse(entry);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    DebugToast.show(
      context,
      'cURL + response copied — opening share…',
      duration: const Duration(milliseconds: 1200),
    );
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: '${entry.methodLabel} ${entry.path}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusTone = toneForStatus(entry.statusKind);
    final methodTone = toneForMethod(entry.method);
    final statusText =
        entry.isPending ? '•••' : (entry.statusCode?.toString() ?? '—');
    final durationText =
        entry.isPending ? 'pending' : '${entry.durationMs ?? 0}ms';

    return Dismissible(
      key: ObjectKey(entry),
      // Swipe either direction copies cURL + response, then snaps back.
      background: _swipeBackground(alignStart: true),
      secondaryBackground: _swipeBackground(alignStart: false),
      confirmDismiss: (_) async {
        await _copyAndShare(context);
        return false;
      },
      child: InkWell(
        onTap: onTap,
        // Long-press to copy cURL + response and open the share sheet.
        onLongPress: () => _copyAndShare(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Fixed-width method column so the path/status line up across
              // rows regardless of the method's length (GET vs PATCH vs …).
              SizedBox(
                width: 60,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusChip(entry.methodLabel, color: methodTone),
                ),
              ),
              // Status moved down next to time/duration so the endpoint (path)
              // gets the full width of the top line.
              Expanded(
                child: _PathAndTime(
                  entry: entry,
                  duration: durationText,
                  statusText: statusText,
                  statusTone: statusTone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Green reveal shown while swiping, labelled "Copy cURL". [alignStart] left-
  /// aligns the label for a left-to-right swipe; otherwise it right-aligns.
  Widget _swipeBackground({required bool alignStart}) {
    return Container(
      color: DebugPalette.success,
      alignment: alignStart ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.copy, size: 18, color: Colors.black),
          SizedBox(width: 8),
          Text(
            'Copy cURL',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-line label inside the tile — endpoint path on top, then
/// time · duration with the status chip to its right.
class _PathAndTime extends StatelessWidget {
  final NetworkEntry entry;
  final String duration;
  final String statusText;
  final Color statusTone;

  const _PathAndTime({
    required this.entry,
    required this.duration,
    required this.statusText,
    required this.statusTone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.path,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: monoStyle(size: 12),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            StatusChip(statusText, color: statusTone),
            const SizedBox(width: 8),
            Text(
              '${formatClock(entry.requestTime)} · $duration',
              style: monoStyle(size: 11, color: DebugPalette.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
