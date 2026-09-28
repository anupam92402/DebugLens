import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/debug_service_source.dart';
import '../../data/service_log_share.dart';
import '../../domain/config_editor.dart';
import '../../domain/service_group.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../widgets/service_config_edit_dialog.dart';
import '../widgets/service_config_view.dart';
import '../widgets/service_config_value_dialog.dart';
import '../widgets/service_entry_tile.dart';
import '../../../../shell/debug_app_bar.dart';
import '../../../../shared/widgets/debug_dialog.dart';
import '../../../../shell/debug_routes.dart';

/// Shows one registered service. Read-only services render a flat,
/// navigation-style list of expandable record rows; a service exposing a
/// [DebugLensConfigEditor] (e.g. Remote Config) renders typed, editable rows
/// with a source toggle. Rows can be searched, copied, shared and cleared, and
/// sorted — newest/oldest for records, A–Z for config keys.
class ServiceDetailScreen extends StatefulWidget {
  final DebugLensService service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen>
    with WidgetsBindingObserver {
  // Loaded read-only data (editable services use the editor instead).
  List<DebugLensServiceGroup> _groups = const [];
  bool _loading = false;

  /// Filter/sort state as notifiers so only the list rebuilds, not the screen.
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  /// Sort A–Z, for the editable path only — config keys read best
  /// alphabetically. Records use [_newestFirst] instead.
  final ValueNotifier<bool> _sortAlpha = ValueNotifier<bool>(true);

  /// Record order for the read-only path — newest first, tap to flip.
  /// newest at the top by default, tap to flip.
  final ValueNotifier<bool> _newestFirst = ValueNotifier<bool>(true);

  /// Bumped whenever the editor's own state moves — a value overridden, the
  /// source switched, overrides reset. The three regions that read the editor
  /// listen to this, so none of it needs a screen-wide rebuild.
  final ValueNotifier<int> _editorRevision = ValueNotifier<int>(0);

  DebugLensConfigEditor? get _editor => widget.service.editor;

  /// Resolved once — a host getter that returns a fresh object each call would
  /// otherwise leave the listener attached to a different instance on dispose.
  late final Listenable? _changes = widget.service.changes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _changes?.addListener(_refresh);
    // Editable services load too: `load()` is optional for them, but any groups
    // it returns render as a status header above the config rows.
    if (_editor == null) {
      // Direct assignment, not setState — the first build hasn't run yet.
      _loading = true;
    }
    _fetch();
  }

  @override
  void dispose() {
    _changes?.removeListener(_refresh);
    WidgetsBinding.instance.removeObserver(this);
    _query.dispose();
    _sortAlpha.dispose();
    _newestFirst.dispose();
    _editorRevision.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  // --- Loading --------------------------------------------------------------

  /// Re-reads the service without clearing the screen — the current rows stay
  /// visible until the new ones arrive, so an auto-refresh never flickers.
  void _refresh() {
    if (!mounted) return;
    // Entries are read straight off the editor; groups still need a pull.
    if (_editor != null) _editorRevision.value++;
    _fetch();
  }

  /// Reads the service, leaving the rows untouched if it throws. There is no
  /// error state: the built-in services read an in-memory list and can't fail,
  /// and a host adapter that does surfaces as an empty list rather than a
  /// dead-end screen with a retry that would only re-run the same call.
  Future<void> _fetch() async {
    try {
      final groups = await widget.service.load();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // --- Visible rows ---------------------------------------------------------
  // Filtering/sorting lives here (not inside the builders) so the share action
  // exports exactly what is on screen.

  String get _q => _query.value.trim().toLowerCase();

  /// Filters the groups, then numbers them by position (oldest = 1) so badges
  /// stay contiguous whatever the search hides and stay with their record
  /// across a sort flip. Returns (group, number) pairs in the chosen order.
  List<_NumberedGroup> get _visibleGroups {
    final q = _q;
    Iterable<DebugLensServiceGroup> out = _groups.reversed;
    if (q.isNotEmpty) {
      out = out.where(
        (g) =>
            g.title.toLowerCase().contains(q) ||
            (g.subtitle ?? '').toLowerCase().contains(q) ||
            g.values.entries.any(
              (e) =>
                  e.key.toLowerCase().contains(q) ||
                  e.value.toLowerCase().contains(q),
            ),
      );
    }
    final filtered = out.toList();
    final numbered = [
      for (var i = 0; i < filtered.length; i++)
        _NumberedGroup(filtered[i], i + 1),
    ];
    return _newestFirst.value ? numbered.reversed.toList() : numbered;
  }

  List<DebugLensConfigEntry> get _visibleEntries {
    final q = _q;
    final visible = _editor!.entries
        .where(
          (e) =>
              q.isEmpty ||
              e.key.toLowerCase().contains(q) ||
              e.value.toLowerCase().contains(q),
        )
        .toList();
    if (_sortAlpha.value) {
      visible.sort(
        (a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()),
      );
    }
    return visible;
  }

  // --- Actions --------------------------------------------------------------

  Future<void> _share() {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final name = widget.service.name;
    return _editor != null
        ? ServiceLogShare.shareEntries(
            name,
            _visibleEntries,
            groups: _groups,
            origin: origin,
          )
        : ServiceLogShare.shareGroups(name, [
            for (final n in _visibleGroups) n.group,
          ], origin: origin);
  }

  Future<void> _clear() async {
    await widget.service.clear();
    if (!mounted) return;
    DebugToast.show(context, DebugStrings.serviceClearedToast);
    _refresh();
  }

  Future<void> _toggleOverride(bool enabled) async {
    // Confirm first so Cancel leaves the source unchanged.
    if (_editor!.requiresRestart) {
      final confirmed = await _showRestartDialog();
      if (confirmed != true) return;
    }
    await _editor!.setOverrideEnabled(enabled);
    _editorRevision.value++;
  }

  Future<void> _reset() async {
    await _editor!.resetOverrides();
    if (!mounted) return;
    // No restart dialog here — it's shown once when switching source.
    DebugToast.show(context, DebugStrings.serviceResetToast);
    _editorRevision.value++;
  }

  Future<void> _editEntry(DebugLensConfigEntry entry) async {
    final value = await showConfigEditDialog(context, entry);
    if (value == null || !mounted) return;
    await _editor!.setValue(entry.key, value);
    if (!mounted) return;

    /// A toast, not a dialog — the value is saved, it just isn't read until the
    /// app restarts. The source switch has its own confirmation.
    DebugToast.show(context, DebugStrings.serviceRestartToast);
    _editorRevision.value++;
  }

  /// Confirms the source switch. Returns true to apply, false/null to cancel.
  Future<bool?> _showRestartDialog() {
    return showDebugDialog<bool>(
      context,
      name: DebugRoutes.serviceRestartDialog,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DebugColors.surface,
        title: const Text(DebugStrings.serviceRestartTitle),
        content: const Text(DebugStrings.serviceRestartMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(DebugStrings.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(DebugStrings.serviceOk),
          ),
        ],
      ),
    );
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final editor = _editor;
    return Scaffold(
      appBar: DebugAppBar(
        title: Text(widget.service.name, style: monoStyle(size: 15)),
        actions: [
          IconButton(
            tooltip: DebugStrings.serviceShareTooltip,
            icon: const Icon(Icons.share),
            onPressed: _share,
          ),
          // Reset only shows in custom mode once overrides exist.
          if (editor != null)
            ValueListenableBuilder<int>(
              valueListenable: _editorRevision,
              builder: (_, _, _) =>
                  editor.overrideEnabled && editor.hasOverrides
                  ? IconButton(
                      tooltip: DebugStrings.serviceResetTooltip,
                      icon: const Icon(Icons.settings_backup_restore),
                      onPressed: _reset,
                    )
                  : const SizedBox.shrink(),
            ),
          // Delete only for read-only services; editable ones use Reset.
          if (editor == null && widget.service.canClear)
            IconButton(
              tooltip: DebugStrings.serviceClearTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: _clear,
            ),
        ],
        bottom: editor == null
            ? null
            : _SourceToggle(
                editor: editor,
                revision: _editorRevision,
                onToggle: _toggleOverride,
              ),
      ),
      body: editor != null
          ? _EditorBody(
              editor: editor,
              groups: _groups,
              changes: Listenable.merge([_query, _sortAlpha, _editorRevision]),
              onSearch: (v) => _query.value = v,
              sortAlpha: _sortAlpha,
              entries: () => _visibleEntries,
              filtered: () => _q.isNotEmpty,
              onEdit: _editEntry,
            )
          : _ReadOnlyBody(
              loading: _loading,
              empty: _groups.isEmpty,
              changes: Listenable.merge([_query, _newestFirst]),
              onSearch: (v) => _query.value = v,
              newestFirst: _newestFirst,
              visible: () => _visibleGroups,
            ),
    );
  }
}

/// Remote / Custom switch under the app bar of an editable service.
class _SourceToggle extends StatelessWidget implements PreferredSizeWidget {
  final DebugLensConfigEditor editor;

  /// Bumped when the editor's state moves.
  final ValueListenable<int> revision;
  final ValueChanged<bool> onToggle;

  const _SourceToggle({
    required this.editor,
    required this.revision,
    required this.onToggle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ValueListenableBuilder<int>(
        valueListenable: revision,
        builder: (_, _, _) => SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              label: Text(editor.sourceLabel),
              icon: const Icon(Icons.cloud_outlined, size: 16),
              tooltip: DebugStrings.serviceSourceRemoteTooltip(
                editor.sourceLabel,
              ),
            ),
            const ButtonSegment(
              value: true,
              label: Text(DebugStrings.serviceSourceCustom),
              icon: Icon(Icons.tune, size: 16),
              tooltip: DebugStrings.serviceSourceCustomTooltip,
            ),
          ],
          selected: {editor.overrideEnabled},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onToggle(s.first),
        ),
      ),
    );
  }
}

/// Search plus [sortControl] — A–Z for config keys, newest/oldest for
/// records. The two modes sort different things, so each brings its own.
class _SearchSortBar extends StatelessWidget {
  final ValueChanged<String> onSearch;
  final Widget sortControl;

  const _SearchSortBar({required this.onSearch, required this.sortControl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: DebugSearchField(
              hint: DebugStrings.serviceSearchHint,
              onChanged: onSearch,
            ),
          ),
          sortControl,
        ],
      ),
    );
  }
}

/// A–Z vs the order the editor lists its keys in.
class _AlphaToggle extends StatelessWidget {
  final ValueNotifier<bool> alpha;

  const _AlphaToggle({required this.alpha});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: alpha,
      builder: (_, on, _) => SortToggle(
        newestFirst: on,
        onToggle: () => alpha.value = !on,
        newestTooltip: DebugStrings.serviceSortAlpha,
        oldestTooltip: DebugStrings.serviceSortOriginal,
      ),
    );
  }
}

/// Newest/oldest over records — the Navigation events tab's control, with
/// `SortToggle`'s default tooltips.
class _OrderToggle extends StatelessWidget {
  final ValueNotifier<bool> newestFirst;

  const _OrderToggle({required this.newestFirst});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: newestFirst,
      builder: (_, newest, _) => SortToggle(
        newestFirst: newest,
        onToggle: () => newestFirst.value = !newest,
      ),
    );
  }
}

/// Body of an editable service (e.g. Remote Config): search, any status
/// groups from `load()`, then the typed config rows.
class _EditorBody extends StatelessWidget {
  final DebugLensConfigEditor editor;
  final List<DebugLensServiceGroup> groups;

  /// Changes that re-filter the rows: query, sort and editor revision.
  final Listenable changes;
  final ValueChanged<String> onSearch;
  final ValueNotifier<bool> sortAlpha;
  final ValueGetter<List<DebugLensConfigEntry>> entries;
  final ValueGetter<bool> filtered;
  final void Function(DebugLensConfigEntry entry) onEdit;

  const _EditorBody({
    required this.editor,
    required this.groups,
    required this.changes,
    required this.onSearch,
    required this.sortAlpha,
    required this.entries,
    required this.filtered,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchSortBar(
          onSearch: onSearch,
          sortControl: _AlphaToggle(alpha: sortAlpha),
        ),
        // Anything `load()` returned — e.g. last fetch time / status. Height-
        // capped and scrollable so a chatty service can't squeeze out the rows.
        if (groups.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final g in groups)
                    SectionCard(
                      title: g.subtitle == null
                          ? g.title
                          : '${g.title} · ${g.subtitle}',
                      child: Column(
                        children: [
                          for (final e in g.values.entries)
                            KvRow(label: e.key, value: e.value),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListenableBuilder(
            listenable: changes,
            builder: (context, _) => ServiceConfigView(
              entries: entries(),
              editable: editor.overrideEnabled,
              filtered: filtered(),
              onEdit: onEdit,
              onView: (entry) => showConfigValueDialog(context, entry),
            ),
          ),
        ),
      ],
    );
  }
}

/// Body of a read-only service (e.g. Analytics / Performance / Crashlytics):
/// a spinner while loading, the empty state, or search over the records.
class _ReadOnlyBody extends StatelessWidget {
  final bool loading;
  final bool empty;

  /// Changes that re-filter the records: query and sort.
  final Listenable changes;
  final ValueChanged<String> onSearch;
  final ValueNotifier<bool> newestFirst;
  final ValueGetter<List<_NumberedGroup>> visible;

  const _ReadOnlyBody({
    required this.loading,
    required this.empty,
    required this.changes,
    required this.onSearch,
    required this.newestFirst,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (empty) {
      return const EmptyState(
        icon: Icons.cloud_off,
        message: DebugStrings.serviceEmpty,
      );
    }
    return Column(
      children: [
        _SearchSortBar(
          onSearch: onSearch,
          sortControl: _OrderToggle(newestFirst: newestFirst),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: changes,
            builder: (context, _) => _GroupList(visible: visible()),
          ),
        ),
      ],
    );
  }
}

/// The visible records, or "no matches" when the query hides them all.
class _GroupList extends StatelessWidget {
  final List<_NumberedGroup> visible;

  const _GroupList({required this.visible});

  @override
  Widget build(BuildContext context) {
    if (visible.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        message: DebugStrings.commonNoMatches,
      );
    }
    return ListView.separated(
      itemCount: visible.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: DebugColors.border),
      itemBuilder: (_, i) =>
          ServiceEntryTile(number: visible[i].number, group: visible[i].group),
    );
  }
}

/// A [DebugLensServiceGroup] paired with its 1-based position in the visible
/// list, so the badge numbers stay contiguous under a filter and follow their
/// record across a sort flip. Mirrors `NumberedNavEvent`; private because the
/// service screen is the only place that numbers groups.
class _NumberedGroup {
  const _NumberedGroup(this.group, this.number);

  final DebugLensServiceGroup group;
  final int number;
}
