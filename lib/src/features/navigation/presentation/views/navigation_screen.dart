import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/debug_store.dart';
import '../../data/nav_log_share.dart';
import '../../../storage/data/debug_shared_prefs_source.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../widgets/nav_events_tab.dart';
import '../widgets/nav_stack_tab.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Two-tab view (Events + Stack) of the navigator observer's captures.
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  final ValueNotifier<bool> _hideInternal = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadHideInternal();
  }

  Future<void> _loadHideInternal() async {
    final saved = await DebugLensSharedPrefs.getBool(
      DebugConstants.navHideInternalPrefsKey,
    );
    if (saved != null && mounted) _hideInternal.value = saved;
  }

  void _toggleHideInternal() {
    _hideInternal.value = !_hideInternal.value;
    DebugLensSharedPrefs.setBool(
      DebugConstants.navHideInternalPrefsKey,
      _hideInternal.value,
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    _hideInternal.dispose();
    super.dispose();
  }

  Future<void> _share(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return NavLogShare.share(
      context.read<DebugStore>(),
      hideDebugLens: _hideInternal.value,
      origin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text(DebugStrings.navigationTitle),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _hideInternal,
            builder: (_, hide, _) => IconButton(
              tooltip: hide
                  ? DebugStrings.navigationShowInternal
                  : DebugStrings.navigationHideInternal,
              icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
              onPressed: _toggleHideInternal,
            ),
          ),
          IconButton(
            tooltip: DebugStrings.navigationShareTooltip,
            icon: const Icon(Icons.share),
            onPressed: () => _share(context),
          ),
          ListenableBuilder(
            listenable: _tab,
            builder: (context, _) => _tab.index != 0
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: DebugStrings.navigationClearTooltip,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      context.read<DebugStore>().clearNavigation();
                      DebugToast.show(
                        context,
                        DebugStrings.navigationClearedToast,
                      );
                    },
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: accent,
          indicatorColor: accent,
          unselectedLabelColor: DebugColors.textMuted,
          tabs: const [
            Tab(text: DebugStrings.navigationTabEvents),
            Tab(text: DebugStrings.navigationTabStack),
          ],
        ),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _hideInternal,
        builder: (_, hide, _) => TabBarView(
          controller: _tab,
          children: [
            NavEventsTab(hideDebugLens: hide),
            NavStackTab(hideDebugLens: hide),
          ],
        ),
      ),
    );
  }
}
