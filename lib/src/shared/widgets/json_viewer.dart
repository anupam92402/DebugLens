import 'package:flutter/material.dart';

import '../debug_strings.dart';
import 'json_engine.dart';
import 'json_object_tree.dart';
import 'json_raw_view.dart';
import 'text_styles.dart';

/// Composite that lets the user toggle between an expandable object tree
/// (`tree`) and pretty-printed JSON text (`raw`) — mirrors the dual-mode
/// viewer in we_logger's chucker, but built on our own widgets.
///
/// The view mode can be left uncontrolled (manages its own state from
/// [initialMode]) or controlled by passing [mode] + [onModeChanged]. When a
/// [search] is supplied, matches are highlighted in whichever mode is active.
class JsonViewer extends StatefulWidget {
  final Object? data;
  final JsonViewMode initialMode;

  /// Controlled view mode. When non-null, the widget renders this mode and
  /// reports toggles through [onModeChanged] instead of tracking its own.
  final JsonViewMode? mode;
  final ValueChanged<JsonViewMode>? onModeChanged;

  /// Active search; when non-null, matches are highlighted in the active mode.
  final JsonSearch? search;

  /// When provided, a `COPY` text button is drawn at the top-right of the
  /// Object/JSON toggle row. It copies the pretty-printed body regardless of
  /// which view mode is active, so the affordance matches the SectionCards on
  /// the Overview tab. [copyLabel] is used in the resulting toast.
  final void Function(String text, String label)? onCopy;
  final String copyLabel;

  const JsonViewer(
    this.data, {
    super.key,
    this.initialMode = JsonViewMode.tree,
    this.mode,
    this.onModeChanged,
    this.search,
    this.onCopy,
    this.copyLabel = DebugStrings.commonBodyLabel,
  });

  @override
  State<JsonViewer> createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  late JsonViewMode _internalMode = widget.initialMode;

  JsonViewMode get _mode => widget.mode ?? _internalMode;

  void _select(JsonViewMode mode) {
    if (widget.onModeChanged != null) {
      widget.onModeChanged!(mode);
    } else {
      setState(() => _internalMode = mode);
    }
  }

  /// Pretty-printed copy text — same representation as the raw JSON view, so
  /// the COPY button yields identical output in both Object and JSON modes.
  String get _copyText => prettyJson(widget.data);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChoiceChip(
              label: const Text(DebugStrings.jsonObjectMode),
              selected: _mode == JsonViewMode.tree,
              onSelected: (_) => _select(JsonViewMode.tree),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text(DebugStrings.jsonRawMode),
              selected: _mode == JsonViewMode.raw,
              onSelected: (_) => _select(JsonViewMode.raw),
            ),
            if (widget.onCopy != null) ...[
              const Spacer(),
              InkWell(
                onTap: () => widget.onCopy!(_copyText, widget.copyLabel),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    DebugStrings.commonCopyButton,
                    style: monoStyle(
                      size: 11,
                      weight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        switch (_mode) {
          JsonViewMode.tree => JsonObjectTree(
            widget.data,
            search: widget.search,
          ),
          JsonViewMode.raw => JsonView(widget.data, search: widget.search),
        },
      ],
    );
  }
}
