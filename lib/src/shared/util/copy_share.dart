import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../debug_strings.dart';
import '../widgets/debug_toast.dart';

/// Copies [text] to the clipboard, confirms with a toast, and opens the system
/// share sheet — the panel's one "get this off the device" gesture.
Future<void> copyAndShare(
  BuildContext context,
  String text, {
  required String label,
  String? subject,
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  DebugToast.show(
    context,
    DebugStrings.commonCopiedShare(label),
    duration: const Duration(milliseconds: 1200),
  );
  await SharePlus.instance.share(
    ShareParams(text: text, subject: subject ?? label),
  );
}
