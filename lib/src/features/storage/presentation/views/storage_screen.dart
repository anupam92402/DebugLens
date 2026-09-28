import 'package:flutter/material.dart';

import '../../data/debug_shared_prefs_source.dart';
import '../../domain/pref_entry.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/util/copy_share.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../widgets/database_tab.dart';
import '../widgets/prefs_tab.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shell/debug_app_bar.dart';

/// Two-tab view of persistent state (SharedPreferences + databases).
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

  /// Hides DebugLens's own `debug_lens_` keys from the Prefs tab.
  final ValueNotifier<bool> _hideInternal = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHideInternal();
  }

  Future<void> _loadHideInternal() async {
    final saved = await DebugLensSharedPrefs.getBool(
      DebugConstants.storageHideInternalPrefsKey,
    );
    if (saved != null && mounted) _hideInternal.value = saved;
  }

  void _toggleHideInternal() {
    _hideInternal.value = !_hideInternal.value;
    DebugLensSharedPrefs.setBool(
      DebugConstants.storageHideInternalPrefsKey,
      _hideInternal.value,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tab.dispose();
    _prefsQuery.dispose();
    _refreshTick.dispose();
    _hideInternal.dispose();
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
    return [
      for (final e in entries)
        if (!_hideInternal.value ||
            !e.key.startsWith(DebugConstants.prefsKeyPrefix))
          e,
    ]..sort((a, b) => a.key.compareTo(b.key));
  }

  Future<void> _copyShare(String text, String label) =>
      copyAndShare(context, text, label: label);

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: DebugAppBar(
        title: const Text(DebugStrings.storageTitle),
        actions: [
          ListenableBuilder(
            listenable: Listenable.merge([_tab, _hideInternal]),
            builder: (_, _) => _tab.index != 0
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: _hideInternal.value
                        ? DebugStrings.storageShowInternal
                        : DebugStrings.storageHideInternal,
                    icon: Icon(
                      _hideInternal.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _toggleHideInternal,
                  ),
          ),
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
            listenable: Listenable.merge([
              _prefsQuery,
              _refreshTick,
              _hideInternal,
            ]),
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
