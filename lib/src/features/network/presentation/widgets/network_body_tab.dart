import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/json_view.dart';
import 'error_banner.dart';

/// Request- or response-body tab content. Both tabs share the same shape:
/// an optional search bar, an optional error banner, then a [JsonViewer]
/// (Object/JSON toggle) for the body. Empty state when there's nothing to
/// show.
///
/// The tab owns the search state (query, view mode, active match) so it can
/// drive the match counter / prev-next controls and scroll the focused match
/// into view via the body's [ScrollController].
class NetworkBodyTab extends StatefulWidget {
  final Object? body;
  final String emptyMessage;

  /// Optional error string — when set, renders a red banner above the body.
  /// Only the response tab uses this; request tab passes `null`.
  final String? error;

  /// When provided, the body viewer shows a COPY button (works in both the
  /// Object and JSON modes). [copyLabel] names the body in the copy toast.
  final void Function(String text, String label)? onCopy;
  final String copyLabel;

  const NetworkBodyTab({
    super.key,
    required this.body,
    required this.emptyMessage,
    this.error,
    this.onCopy,
    this.copyLabel = DebugStrings.commonBodyLabel,
  });

  @override
  State<NetworkBodyTab> createState() => _NetworkBodyTabState();
}

class _NetworkBodyTabState extends State<NetworkBodyTab> {
  final ScrollController _scroll = ScrollController();
  // Recreated each time the active match moves so the framework re-runs the
  // ensureVisible post-frame callback against the freshly mounted target.
  GlobalKey _activeKey = GlobalKey();

  String _query = '';
  JsonViewMode _mode = JsonViewMode.tree;
  int _activeIndex = 0;

  int get _matchCount =>
      _query.isEmpty ? 0 : jsonMatchCount(widget.body, _query, _mode);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value.trim();
      _activeIndex = 0;
      _activeKey = GlobalKey();
    });
    _scheduleScrollToActive();
  }

  void _onModeChanged(JsonViewMode mode) {
    setState(() {
      _mode = mode;
      _activeIndex = 0;
      _activeKey = GlobalKey();
    });
    _scheduleScrollToActive();
  }

  void _step(int delta) {
    final count = _matchCount;
    if (count == 0) return;
    setState(() {
      _activeIndex = (_activeIndex + delta + count) % count;
      _activeKey = GlobalKey();
    });
    _scheduleScrollToActive();
  }

  void _scheduleScrollToActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _activeKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.body == null && widget.error == null) {
      return EmptyState(icon: Icons.data_object, message: widget.emptyMessage);
    }

    final count = _matchCount;
    final activeIndex = count == 0 ? 0 : _activeIndex.clamp(0, count - 1);
    final search = (_query.isNotEmpty && count > 0)
        ? JsonSearch(
            query: _query.toLowerCase(),
            activeIndex: activeIndex,
            activeKey: _activeKey,
          )
        : null;

    return Column(
      children: [
        if (widget.body != null) _searchBar(count, activeIndex),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            children: [
              if (widget.error != null) ErrorBanner(message: widget.error!),
              if (widget.body != null)
                JsonViewer(
                  widget.body,
                  mode: _mode,
                  onModeChanged: _onModeChanged,
                  search: search,
                  onCopy: widget.onCopy,
                  copyLabel: widget.copyLabel,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchBar(int count, int activeIndex) {
    final searching = _query.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: DebugSearchField(
              hint: DebugStrings.networkSearchBody(widget.copyLabel),
              onChanged: _onQueryChanged,
            ),
          ),
          if (searching) ...[
            const SizedBox(width: 8),
            Text(
              count == 0
                  ? DebugStrings.commonNoMatches
                  : '${activeIndex + 1}/$count',
              style: monoStyle(
                size: 12,
                color: count == 0 ? DebugPalette.textMuted : DebugPalette.info,
              ),
            ),
            IconButton(
              tooltip: DebugStrings.networkPrevMatch,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
              color: DebugPalette.textMuted,
              onPressed: count == 0 ? null : () => _step(-1),
            ),
            IconButton(
              tooltip: DebugStrings.networkNextMatch,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              color: DebugPalette.textMuted,
              onPressed: count == 0 ? null : () => _step(1),
            ),
          ],
        ],
      ),
    );
  }
}
