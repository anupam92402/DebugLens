import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/debug_shared_prefs_source.dart';
import '../../domain/pref_entry.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../widgets/database_tab.dart';
import '../widgets/prefs_tab.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Two-tab view of persistent state (SharedPreferences + databases).
///
/// Pull-based: the prefs tab reads the host-registered
/// [DebugLensSharedPrefs.source] on each build (no copy kept); the refresh
/// action re-pulls it.
class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final ValueNotifier<String> _prefsQuery = ValueNotifier<String>('');

  // Bumped to re-pull the live prefs snapshot / re-read the DB registry — no
  // screen-wide setState needed. Driven by the refresh action and app resume.
  final ValueNotifier<int> _refreshTick = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tab.dispose();
    _prefsQuery.dispose();
    _refreshTick.dispose();
    super.dispose();
  }

  // Storage is pull-based, so data can go stale while the app is backgrounded
  // (edited elsewhere). Re-pull on resume so it's fresh when you return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshTick.value++;
  }

  void _refresh() {
    _refreshTick.value++;
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

  /// Copies [text] to the clipboard and opens the system share sheet.
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
          unselectedLabelColor: DebugColors.textMuted,
          tabs: const [
            Tab(text: DebugStrings.storageTabPrefs),
            Tab(text: DebugStrings.storageTabDatabase),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([_prefsQuery, _refreshTick]),
            builder: (_, _) => PrefsTab(
              entries: _prefEntries(),
              query: _prefsQuery.value,
              onSearch: (v) => _prefsQuery.value = v,
              onCopyShare: _copyShare,
            ),
          ),
          DatabaseTab(refresh: _refreshTick),
        ],
      ),
    );
  }
}
