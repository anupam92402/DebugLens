import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/config_editor.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Prompts for a new value for [entry], returning it in string form or null if
/// cancelled. Booleans use a segmented true/false control; other types use a
/// text field.
///
/// The returned string always satisfies [DebugLensConfigType.accepts] — Save
/// stays disabled while the input is unparseable — so the host never has to
/// defend against a malformed edit.
Future<String?> showConfigEditDialog(
  BuildContext context,
  DebugLensConfigEntry entry,
) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ConfigEditDialog(entry: entry),
  );
}

class _ConfigEditDialog extends StatefulWidget {
  final DebugLensConfigEntry entry;

  const _ConfigEditDialog({required this.entry});

  @override
  State<_ConfigEditDialog> createState() => _ConfigEditDialogState();
}

class _ConfigEditDialogState extends State<_ConfigEditDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.entry.value,
  )..addListener(() => setState(() {}));
  late bool _boolValue = _asBool(widget.entry.value);

  static bool _asBool(String v) => v.toLowerCase() == DebugConstants.trueValue;

  DebugLensConfigType get _type => widget.entry.type;

  bool get _isBool => _type == DebugLensConfigType.boolean;

  /// The value this dialog would return right now.
  String get _pending => _isBool
      ? (_boolValue ? DebugConstants.trueValue : DebugConstants.falseValue)
      : _controller.text.trim();

  /// A bool is always valid (it comes from the segmented control); a typed text
  /// field must parse. Blocks `1.2.3`, a lone `-`, an empty number, …
  bool get _isValid => _type.accepts(_pending);

  /// Number keyboard for numeric types.
  TextInputType get _keyboardType {
    switch (_type) {
      case DebugLensConfigType.integer:
        return const TextInputType.numberWithOptions(signed: true);
      case DebugLensConfigType.double:
        return const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        );
      case DebugLensConfigType.boolean:
      case DebugLensConfigType.string:
        return TextInputType.text;
    }
  }

  /// Restricts typed characters so an int can't take letters (and a double only
  /// digits / sign / decimal point). Shape is still checked by [_isValid] —
  /// these formatters narrow the alphabet, they don't validate.
  List<TextInputFormatter> get _formatters {
    switch (_type) {
      case DebugLensConfigType.integer:
        return [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))];
      case DebugLensConfigType.double:
        return [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))];
      case DebugLensConfigType.boolean:
      case DebugLensConfigType.string:
        return const [];
    }
  }

  /// Reverts the field to the original source-of-truth value in place.
  void _resetToSource() {
    final v = widget.entry.sourceValue;
    if (v == null) return;
    setState(() {
      _controller.text = v;
      _boolValue = _asBool(v);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DebugColors.surface,
      title: Text(
        DebugStrings.serviceEditTitle(widget.entry.key),
        style: monoStyle(size: 14),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isBool)
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text(DebugStrings.commonTrue),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(DebugStrings.commonFalse),
                ),
              ],
              selected: {_boolValue},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _boolValue = s.first),
            )
          else
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: _keyboardType,
              inputFormatters: _formatters,
              style: monoStyle(size: 13),
              decoration: InputDecoration(
                errorText: _isValid
                    ? null
                    : DebugStrings.serviceInvalidValue(_type.label),
                errorStyle: monoStyle(size: 11, color: DebugColors.error),
              ),
            ),
          if (widget.entry.sourceValue != null) ...[
            const SizedBox(height: 8),
            Text(
              '${DebugStrings.serviceSourceValueLabel}: '
              '${widget.entry.sourceValue}',
              style: monoStyle(size: 11, color: DebugColors.textMuted),
            ),
          ],
        ],
      ),
      actions: [
        if (widget.entry.sourceValue != null)
          TextButton(
            onPressed: _resetToSource,
            child: const Text(DebugStrings.serviceResetLabel),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(DebugStrings.commonCancel),
        ),
        TextButton(
          onPressed: _isValid
              ? () => Navigator.of(context).pop(_pending)
              : null,
          child: const Text(DebugStrings.serviceSave),
        ),
      ],
    );
  }
}
