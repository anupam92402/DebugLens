import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/debug_shared_prefs_source.dart';
import '../../domain/pref_entry.dart';
import '../../../../core/debug_store.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../widgets/database_tab.dart';
import '../widgets/prefs_tab.dart';

/// Two-tab view of persistent state (SharedPreferences + tables).
///
/// The SharedPrefs tab reads the app's live preferences from the
/// host-registered [DebugLensSharedPrefs.source] on each build — DebugLens
/// stores no copy. The AppBar refresh action re-pulls whichever tab is open.
/// Both tab bodies live in `widgets/storage/`.
class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  String _prefsQuery = '';

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  /// Re-pulls data for whichever tab is currently open. SharedPrefs data is
  /// pulled fresh from the source on rebuild; the Database tab re-reads the
  /// store. A `setState` is enough since both bodies read their data in build.
  void _refresh() {
    setState(() {});
    final which = _tab.index == 0
        ? DebugStrings.storageTabPrefs
        : DebugStrings.storageTabDatabase;
    DebugToast.show(
      context,
      DebugStrings.storageRefreshed(which),
      duration: const Duration(milliseconds: 1000),
    );
  }

  /// Live snapshot of the app's prefs, sorted by key. No copy is retained.
  List<DebugLensPrefEntry> _prefEntries() {
    final entries = DebugLensSharedPrefs.source?.call() ?? const [];
    return [...entries]..sort((a, b) => a.key.compareTo(b.key));
  }

  /// Copies [text] to the clipboard and opens the system share sheet — the
  /// same affordance as the Network screen's copy actions.
  Future<void> _copyShare(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    DebugToast.show(
      context,
      DebugStrings.commonCopiedShare(label),
      duration: const Duration(milliseconds: 1200),
    );
    await SharePlus.instance.share(ShareParams(text: text, subject: label));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final store = context.watch<DebugStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(DebugStrings.storageTitle),
        actions: [
          IconButton(
            tooltip: DebugStrings.storageRefreshTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: accent,
          indicatorColor: accent,
          unselectedLabelColor: DebugPalette.textMuted,
          tabs: const [
            Tab(text: DebugStrings.storageTabPrefs),
            Tab(text: DebugStrings.storageTabDatabase),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          PrefsTab(
            entries: _prefEntries(),
            query: _prefsQuery,
            onSearch: (v) => setState(() => _prefsQuery = v),
            onCopyShare: _copyShare,
          ),
          const DatabaseTab(),
        ],
      ),
    );
  }
}
