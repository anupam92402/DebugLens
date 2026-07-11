import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Password gate shown before switching to developer mode. Pops `true` on the
/// correct password, `false`/`null` otherwise.
class DeveloperPasswordDialog extends StatefulWidget {
  const DeveloperPasswordDialog({super.key});

  @override
  State<DeveloperPasswordDialog> createState() =>
      _DeveloperPasswordDialogState();
}

class _DeveloperPasswordDialogState extends State<DeveloperPasswordDialog> {
  static const String _password = '123456';

  final TextEditingController _controller = TextEditingController();
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text == _password) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DebugColors.surface,
      title: Text(
        DebugStrings.dashboardDeveloperAccess,
        style: monoStyle(size: 15),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        style: monoStyle(size: 14),
        onChanged: (_) {
          if (_error) setState(() => _error = false);
        },
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: DebugStrings.dashboardPasswordHint,
          errorText: _error ? DebugStrings.dashboardPasswordError : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(DebugStrings.commonCancel),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text(DebugStrings.dashboardUnlock),
        ),
      ],
    );
  }
}
