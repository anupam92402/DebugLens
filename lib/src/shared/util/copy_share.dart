import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../debug_strings.dart';
import '../widgets/debug_toast.dart';

/// Copies [text] to the clipboard, confirms with a toast, and opens the system
/// share sheet — the panel's one "get this off the device" gesture.
///
/// [label] names what was copied, both in the toast and as the share subject
/// unless [subject] overrides it.
///
/// The toast is deliberately short: the share sheet slides up right behind it,
/// and a toast still sitting there under the sheet reads as stuck.
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
