import 'package:flutter/material.dart';

import '../theme/debug_theme.dart';
import 'glass.dart';

// Re-exported so screens importing `widgets/debug_widgets.dart` still see
// `formatClock` without changing every import in this refactor pass. New
// code should import `util/clock_format.dart` directly.
export '../../util/clock_format.dart' show formatClock;

String formatAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return '${d.inSeconds}s ago';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

TextStyle monoStyle({double size = 12, Color? color, FontWeight? weight}) =>
    TextStyle(
      fontFamily: DebugPalette.mono,
      fontSize: size,
      color: color ?? DebugPalette.textPrimary,
      fontWeight: weight,
    );

/// Small colored pill used for HTTP methods, status codes, log levels, etc.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const StatusChip(this.label, {super.key, required this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: monoStyle(
          size: 11,
          weight: FontWeight.w700,
          color: filled ? Colors.black : color,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: DebugPalette.textMuted),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: DebugPalette.textMuted)),
        ],
      ),
    );
  }
}

/// Titled, bordered container used to group content on detail screens.
///
/// When [onCopy] is provided, a compact `Copy` text button is drawn at the
/// top-right of the title row — same affordance as we_logger's chucker
/// overview, where every block has a one-tap copy.
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onCopy;

  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || onCopy != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!.toUpperCase(),
                        style: monoStyle(
                          size: 11,
                          weight: FontWeight.w700,
                          color: DebugPalette.textMuted,
                        ),
                      ),
                    ),
                  if (onCopy != null)
                    InkWell(
                      onTap: onCopy,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                          'COPY',
                          style: monoStyle(
                            size: 11,
                            weight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class DebugSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const DebugSearchField({super.key, required this.hint, required this.onChanged});

  @override
  State<DebugSearchField> createState() => _DebugSearchFieldState();
}

class _DebugSearchFieldState extends State<DebugSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rebuild so the clear icon shows/hides as the text changes.
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: monoStyle(size: 13),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        hintStyle: monoStyle(size: 13, color: DebugPalette.textMuted),
        prefixIcon: const Icon(Icons.search, size: 18, color: DebugPalette.textMuted),
        suffixIcon: hasText
            ? IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close,
                    size: 18, color: DebugPalette.textMuted),
                onPressed: _clear,
              )
            : null,
        filled: true,
        fillColor: DebugPalette.glassFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DebugPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DebugPalette.border),
        ),
      ),
    );
  }
}

/// Label/value row. When [sensitive] is true the value is masked with a
/// tap-to-reveal toggle.
class KvRow extends StatefulWidget {
  final String label;
  final String value;
  final bool sensitive;

  const KvRow({
    super.key,
    required this.label,
    required this.value,
    this.sensitive = false,
  });

  @override
  State<KvRow> createState() => _KvRowState();
}

class _KvRowState extends State<KvRow> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final masked = widget.sensitive && !_revealed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              widget.label,
              style: monoStyle(size: 12, color: DebugPalette.textMuted),
            ),
          ),
          Expanded(
            child: SelectableText(
              masked ? '•' * 12 : widget.value,
              style: monoStyle(size: 12),
            ),
          ),
          if (widget.sensitive)
            GestureDetector(
              onTap: () => setState(() => _revealed = !_revealed),
              child: Icon(
                _revealed ? Icons.visibility_off : Icons.visibility,
                size: 16,
                color: DebugPalette.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
