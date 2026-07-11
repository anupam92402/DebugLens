import 'package:flutter/material.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Red-tinted banner used to surface the error message on the Response tab
/// when the request failed.
class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner({super.key, required this.message});

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
      child: Text(
        message,
        style: monoStyle(size: 12, color: DebugColors.error),
      ),
    );
  }
}
