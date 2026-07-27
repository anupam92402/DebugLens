import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../data/app_version_store.dart';

/// Prompts for a device-local app version, applied on the next app start.
Future<void> showAppVersionDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _AppVersionDialog(),
  );
}

class _AppVersionDialog extends StatefulWidget {
  const _AppVersionDialog();

  @override
  State<_AppVersionDialog> createState() => _AppVersionDialogState();
}

class _AppVersionDialogState extends State<_AppVersionDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: AppVersionStore.instance.pending,
  )..addListener(() => setState(() {}));

  String get _value => _controller.text.trim();

  /// Anything non-blank goes: version strings have no one format, and a host
  /// may want `1.0.0`, `1.0.0+42` or `1.0.0-rc.1`.
  bool get _isValid => _value.isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await AppVersionStore.instance.setOverride(_value);
    if (!mounted) return;
    Navigator.of(context).pop();
    DebugToast.show(context, DebugStrings.serviceRestartToast);
  }

  Future<void> _reset() async {
    await AppVersionStore.instance.reset();
    if (!mounted) return;
    Navigator.of(context).pop();
    DebugToast.show(context, DebugStrings.serviceRestartToast);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppVersionStore.instance;
    return AlertDialog(
      backgroundColor: DebugColors.surface,
      title: Text(DebugStrings.settingsAppVersion, style: monoStyle(size: 14)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            style: monoStyle(size: 13),
            decoration: InputDecoration(
              errorText: _isValid ? null : DebugStrings.appVersionInvalid,
              errorStyle: monoStyle(size: 11, color: DebugColors.error),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${DebugStrings.appVersionOriginal}: ${store.source}',
            style: monoStyle(size: 11, color: DebugColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            DebugStrings.serviceRestartMessage,
            style: monoStyle(size: 11, color: DebugColors.warning),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: store.isOverridden ? _reset : null,
          child: const Text(DebugStrings.serviceResetLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(DebugStrings.commonCancel),
        ),
        TextButton(
          onPressed: _isValid ? _save : null,
          child: const Text(DebugStrings.serviceOk),
        ),
      ],
    );
  }
}
