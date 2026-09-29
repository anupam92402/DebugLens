import 'dart:async';

import 'package:flutter/material.dart';

import '../debug_strings.dart';
import 'text_styles.dart';
import '../theme/debug_colors.dart';

/// Search input with a search prefix icon and a clear button that appears once
/// there's text. Reports changes through [onChanged], [debounce] after the
/// last keystroke; clearing reports at once.
class DebugSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  /// Delay before a typed change is reported. [Duration.zero] reports each one.
  final Duration debounce;

  const DebugSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.debounce = Duration.zero,
  });

  @override
  State<DebugSearchField> createState() => _DebugSearchFieldState();
}

class _DebugSearchFieldState extends State<DebugSearchField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Rebuild so the clear icon shows/hides as the text changes.
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  void _onInput(String value) {
    if (widget.debounce == Duration.zero) return widget.onChanged(value);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () => widget.onChanged(value));
  }

  void _clear() {
    _debounceTimer?.cancel();
    _controller.clear();
    widget.onChanged('');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    return TextField(
      controller: _controller,
      onChanged: _onInput,
      style: monoStyle(size: 13),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        hintStyle: monoStyle(size: 13, color: DebugColors.textMuted),
        prefixIcon: const Icon(
          Icons.search,
          size: 18,
          color: DebugColors.textMuted,
        ),
        suffixIcon: hasText
            ? IconButton(
                tooltip: DebugStrings.commonClear,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: DebugColors.textMuted,
                ),
                onPressed: _clear,
              )
            : null,
        filled: true,
        fillColor: DebugColors.glassFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DebugColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DebugColors.border),
        ),
      ),
    );
  }
}
