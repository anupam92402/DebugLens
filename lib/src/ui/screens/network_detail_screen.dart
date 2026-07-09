import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/network_entry.dart';
import '../../util/network_serializer.dart';
import '../theme/debug_theme.dart';
import '../widgets/debug_toast.dart';
import '../widgets/debug_widgets.dart';
import '../widgets/network/network_body_tab.dart';
import '../widgets/network/network_overview_tab.dart';

/// Tabbed view of a single network entry. Owns the AppBar (method chip,
/// path, copy+share actions) and the three tabs (Overview / Request /
/// Response). Each tab body is its own widget so this file stays focused
/// on layout and copy/share wiring.
class NetworkDetailScreen extends StatelessWidget {
  final NetworkEntry entry;

  const NetworkDetailScreen({super.key, required this.entry});

  // --- copy / share helpers ----------------------------------------------

  /// Clipboard-only — used by per-SectionCard COPY buttons.
  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    DebugToast.show(
      context,
      '$label copied',
      duration: const Duration(milliseconds: 1200),
    );
  }

  /// Clipboard + open the system share sheet — used by the AppBar's two
  /// "Copy + share …" actions. Matches the copy icon on Network list rows.
  Future<void> _copyAndShare(
    BuildContext context,
    String text,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    DebugToast.show(
      context,
      '$label copied — opening share…',
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
    final accent = Theme.of(context).colorScheme.primary;
    final methodTone = toneForMethod(entry.method);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              StatusChip(entry.methodLabel, color: methodTone),
              const SizedBox(width: 8),
              Expanded(
                child: Text(entry.path,
                    overflow: TextOverflow.ellipsis,
                    style: monoStyle(size: 14)),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Copy + share full request',
              icon: const Icon(Icons.copy_all),
              onPressed: () => _copyAndShare(
                  context, NetworkSerializer.formatEntry(entry), 'Request'),
            ),
            IconButton(
              tooltip: 'Copy + share cURL',
              icon: const Icon(Icons.terminal),
              onPressed: () => _copyAndShare(
                  context, NetworkSerializer.renderCurl(entry), 'cURL'),
            ),
          ],
          bottom: TabBar(
            labelColor: accent,
            indicatorColor: accent,
            unselectedLabelColor: DebugPalette.textMuted,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Request'),
              Tab(text: 'Response'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            NetworkOverviewTab(
              entry: entry,
              onCopy: (text, label) => _copy(context, text, label),
            ),
            NetworkBodyTab(
              body: entry.requestBody,
              emptyMessage: 'No request body',
              copyLabel: 'Request body',
              onCopy: (text, label) => _copy(context, text, label),
            ),
            NetworkBodyTab(
              body: entry.responseBody,
              emptyMessage: 'No response body',
              error: entry.error,
              copyLabel: 'Response',
              onCopy: (text, label) => _copy(context, text, label),
            ),
          ],
        ),
      ),
    );
  }
}
