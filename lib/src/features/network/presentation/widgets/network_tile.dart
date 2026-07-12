import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/network_entry.dart';
import '../../data/network_serializer.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import 'path_and_time.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Single row in the Network list screen.
///
/// Affordances:
///   - tapping the row → navigate to detail (handled by [onTap])
///   - swipe left→right → copy + share cURL only
///   - swipe right→left → copy + share cURL + response
class NetworkTile extends StatelessWidget {
  final NetworkEntry entry;
  final VoidCallback onTap;

  const NetworkTile({super.key, required this.entry, required this.onTap});

  /// Copies [text] to the clipboard and opens the share sheet; [toast] confirms
  /// what was copied (kept so users can paste even if they dismiss the sheet).
  Future<void> _copyAndShare(
    BuildContext context,
    String text,
    String toast,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    DebugToast.show(
      context,
      toast,
      duration: const Duration(milliseconds: 1200),
    );
    await SharePlus.instance.share(
      ShareParams(text: text, subject: '${entry.methodLabel} ${entry.path}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusTone = toneForStatus(entry.statusKind);
    final methodTone = toneForMethod(entry.method);
    final statusText = entry.isPending
        ? DebugConstants.pendingIndicator
        : (entry.statusCode?.toString() ?? DebugConstants.emptyValue);
    final durationText = entry.isPending
        ? DebugStrings.networkPending
        : '${entry.durationMs ?? 0}ms';

    return Dismissible(
      key: ObjectKey(entry),
      background: _swipeLabel(DebugStrings.networkSwipeCurl, alignStart: true),
      secondaryBackground: _swipeLabel(
        DebugStrings.networkSwipeCurlResponse,
        alignStart: false,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Left → right: cURL only.
          await _copyAndShare(
            context,
            NetworkSerializer.renderCurl(entry),
            DebugStrings.networkCopyCurlToast,
          );
        } else {
          // Right → left: cURL + response.
          await _copyAndShare(
            context,
            NetworkSerializer.formatCurlPlusResponse(entry),
            DebugStrings.networkCopyShareToast,
          );
        }
        return false; // never dismiss — the row snaps back
      },
      child: InkWell(
        onTap: onTap,
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
              const SizedBox(width: 10),
              // Status moved down next to time/duration so the endpoint (path)
              // gets the full width of the top line.
              Expanded(
                child: PathAndTime(
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

  /// Green reveal shown while swiping, labelled [label]. [alignStart] left-
  /// aligns for a left→right swipe; otherwise it right-aligns.
  Widget _swipeLabel(String label, {required bool alignStart}) {
    return Container(
      color: DebugColors.success,
      alignment: alignStart ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.copy, size: 18, color: Colors.black),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
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
