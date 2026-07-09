import 'package:flutter/material.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Error view with a retry action — load failures are common for live Firebase
/// wrappers (no network, not initialised, …), so make recovery one tap.
class ErrorState extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 46, color: DebugPalette.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              DebugStrings.firebaseLoadFailed(error),
              textAlign: TextAlign.center,
              style: monoStyle(size: 12, color: DebugPalette.textMuted),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(DebugStrings.commonRetry),
          ),
        ],
      ),
    );
  }
}
