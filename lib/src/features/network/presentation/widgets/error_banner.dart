import 'package:flutter/material.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Red-tinted banner surfacing the error on the Response tab. Shows a copy
/// icon when [onCopy] is provided.
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onCopy;

  const ErrorBanner({super.key, required this.message, this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DebugColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DebugColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              message,
              style: monoStyle(size: 12, color: DebugColors.error),
            ),
          ),
          if (onCopy != null)
            CopyIcon(tooltip: DebugStrings.networkCopyError, onTap: onCopy!),
        ],
      ),
    );
  }
}
