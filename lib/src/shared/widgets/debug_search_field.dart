import 'package:flutter/material.dart';

import '../debug_strings.dart';
import '../theme/debug_theme.dart';
import 'text_styles.dart';

/// Search input with a search prefix icon and a clear button that appears once
/// there's text. Reports every change through [onChanged].
class DebugSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const DebugSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

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
        prefixIcon: const Icon(
          Icons.search,
          size: 18,
          color: DebugPalette.textMuted,
        ),
        suffixIcon: hasText
            ? IconButton(
                tooltip: DebugStrings.commonClear,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: DebugPalette.textMuted,
                ),
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
