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
import '../widgets/service_entry_tile.dart';
import '../widgets/service_error_state.dart';

/// Shows one registered service. Read-only services render a flat,
/// navigation-style list of expandable record rows; a service exposing a
/// [DebugLensConfigEditor] (e.g. Remote Config) renders typed, editable rows
/// with a source toggle. Rows can be searched, sorted A–Z, copied, shared and
/// cleared.
///
/// Read-only data is re-pulled on demand (refresh action), when the app
/// resumes, and whenever the service signals through `DebugLensService.changes`
/// — so a screen left open keeps up with records arriving behind it.
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
  Object? _loadError;
  bool _loading = false;

  /// Filter/sort state as notifiers so only the list rebuilds, not the screen.
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  /// Sort A–Z. Defaults on for editable configs (keys read best alphabetically)
  /// and off for read-only records (which keep their natural, recent-first
  /// order until toggled).
  late final ValueNotifier<bool> _sortAlpha = ValueNotifier<bool>(
    widget.service.editor != null,
  );

  /// Whether host-flagged sensitive values are currently unmasked.
  final ValueNotifier<bool> _revealSensitive = ValueNotifier<bool>(false);

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
    _revealSensitive.dispose();
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
    if (_editor != null) setState(() {});
    _fetch();
  }

  /// Retry after a failure: show the spinner, since there is nothing to keep.
  void _retry() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final groups = await widget.service.load();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loadError = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  // --- Visible rows ---------------------------------------------------------
  // Filtering/sorting lives here (not inside the builders) so the share action
  // exports exactly what is on screen.

  String get _q => _query.value.trim().toLowerCase();

  List<DebugLensServiceGroup> get _visibleGroups {
    final q = _q;
    final visible = q.isEmpty
        ? _groups.toList()
        : _groups.where((g) {
            if (g.title.toLowerCase().contains(q)) return true;
            if ((g.subtitle ?? '').toLowerCase().contains(q)) return true;
            // Search what is actually on screen — a masked secret must not be
            // findable by its hidden value.
            final searchable = _revealSensitive.value
                ? g.values
                : g.maskedValues;
            return searchable.entries.any(
              (e) =>
                  e.key.toLowerCase().contains(q) ||
                  e.value.toLowerCase().contains(q),
            );
          }).toList();
    if (_sortAlpha.value) {
      visible.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }
    return visible;
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
        : ServiceLogShare.shareGroups(name, _visibleGroups, origin: origin);
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
    if (mounted) setState(() {});
  }

  Future<void> _reset() async {
    await _editor!.resetOverrides();
    if (!mounted) return;
    // No restart dialog here — it's shown once when switching source.
    DebugToast.show(context, DebugStrings.serviceResetToast);
    setState(() {});
  }

  Future<void> _editEntry(DebugLensConfigEntry entry) async {
    final value = await showConfigEditDialog(context, entry);
    if (value == null || !mounted) return;
    await _editor!.setValue(entry.key, value);
    // No restart dialog per edit — it's shown once when switching to custom.
    if (mounted) setState(() {});
  }

  /// Confirms the source switch. Returns true to apply, false/null to cancel.
  Future<bool?> _showRestartDialog() {
    return showDialog<bool>(
      context: context,
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
      appBar: AppBar(
        title: Text(widget.service.name, style: monoStyle(size: 15)),
        actions: [
          // Read-only data is pulled; give it an explicit re-pull too.
          if (editor == null)
            IconButton(
              tooltip: DebugStrings.serviceRefreshTooltip,
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
            ),
          IconButton(
            tooltip: DebugStrings.serviceShareTooltip,
            icon: const Icon(Icons.share),
            onPressed: _share,
          ),
          // Reset only shows in custom mode once overrides exist.
          if (editor != null && editor.overrideEnabled && editor.hasOverrides)
            IconButton(
              tooltip: DebugStrings.serviceResetTooltip,
              icon: const Icon(Icons.settings_backup_restore),
              onPressed: _reset,
            ),
          // Delete only for read-only services; editable ones use Reset.
          if (editor == null && widget.service.canClear)
            IconButton(
              tooltip: DebugStrings.serviceClearTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: _clear,
            ),
        ],
        bottom: editor == null ? null : _sourceToggle(editor),
      ),
      body: editor != null ? _buildEditor(editor) : _buildReadOnly(),
    );
  }

  PreferredSizeWidget _sourceToggle(DebugLensConfigEditor editor) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: SegmentedButton<bool>(
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
          onSelectionChanged: (s) => _toggleOverride(s.first),
        ),
      ),
    );
  }

  /// Search + sort, plus the reveal toggle when the data holds secrets.
  Widget _searchSortBar({bool canReveal = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: DebugSearchField(
              hint: DebugStrings.serviceSearchHint,
              onChanged: (v) => _query.value = v,
            ),
          ),
          if (canReveal)
            ValueListenableBuilder<bool>(
              valueListenable: _revealSensitive,
              builder: (_, reveal, _) => IconButton(
                tooltip: reveal
                    ? DebugStrings.serviceHideSensitive
                    : DebugStrings.serviceShowSensitive,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  reveal ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: DebugColors.textMuted,
                ),
                onPressed: () => _revealSensitive.value = !reveal,
              ),
            ),
          ValueListenableBuilder<bool>(
            valueListenable: _sortAlpha,
            builder: (_, alpha, _) => SortToggle(
              newestFirst: alpha,
              onToggle: () => _sortAlpha.value = !alpha,
              newestTooltip: DebugStrings.serviceSortAlpha,
              oldestTooltip: DebugStrings.serviceSortOriginal,
            ),
          ),
        ],
      ),
    );
  }

  // --- Editable (e.g. Remote Config) ----------------------------------------

  Widget _buildEditor(DebugLensConfigEditor editor) {
    return Column(
      children: [
        _searchSortBar(),
        // Anything `load()` returned — e.g. last fetch time / status. Height-
        // capped and scrollable so a chatty service can't squeeze out the rows.
        if (_groups.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final g in _groups)
                    SectionCard(
                      title: g.subtitle == null
                          ? g.title
                          : '${g.title} · ${g.subtitle}',
                      child: Column(
                        children: [
                          for (final e in g.values.entries)
                            KvRow(
                              label: e.key,
                              value: e.value,
                              sensitive: g.isSensitive(e.key),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge([_query, _sortAlpha]),
            builder: (context, _) => ServiceConfigView(
              entries: _visibleEntries,
              editable: editor.overrideEnabled,
              filtered: _q.isNotEmpty,
              onEdit: _editEntry,
            ),
          ),
        ),
      ],
    );
  }

  // --- Read-only (e.g. Analytics / Performance / Crashlytics) ---------------

  Widget _buildReadOnly() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return ServiceErrorState(error: _loadError, onRetry: _retry);
    }
    if (_groups.isEmpty) {
      return const EmptyState(
        icon: Icons.cloud_off,
        message: DebugStrings.serviceEmpty,
      );
    }
    final canReveal = _groups.any((g) => g.hasSensitive);
    return Column(
      children: [
        _searchSortBar(canReveal: canReveal),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _query,
              _sortAlpha,
              _revealSensitive,
            ]),
            builder: (context, _) => _buildList(),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    final visible = _visibleGroups;
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
      itemBuilder: (_, i) => ServiceEntryTile(
        number: i + 1,
        group: visible[i],
        revealSensitive: _revealSensitive.value,
      ),
    );
  }
}
