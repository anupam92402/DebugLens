import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/util/copy_share.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// Replacement for Flutter's red error box, showing the exception and its stack
/// trace as two copyable blocks.
///
/// Wire it from the host once, at startup:
///
/// ```dart
/// ErrorWidget.builder = (details) => CustomErrorScreen(details: details);
/// ```

class CustomErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;

  const CustomErrorScreen({super.key, required this.details});

  String get _error => details.exceptionAsString();

  String get _stack =>
      details.stack?.toString().trimRight() ?? DebugStrings.errorScreenNoStack;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: DebugColors.bg,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: DebugColors.error,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DebugStrings.errorScreenTitle,
                      style: monoStyle(size: 15, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DebugStrings.errorScreenSubtitle,
                style: monoStyle(size: 11, color: DebugColors.textMuted),
              ),
              const SizedBox(height: 16),
              ErrorReportBlock(
                header: DebugStrings.errorScreenErrorHeader,
                label: DebugStrings.errorScreenErrorLabel,
                body: _error,
                tone: DebugColors.error,
              ),
              const SizedBox(height: 12),
              ErrorReportBlock(
                header: DebugStrings.commonStackHeader,
                label: DebugStrings.errorScreenStackLabel,
                body: _stack,
                tone: DebugColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header + copy action over a code block, as used by [CustomErrorScreen].
///
/// The copy control is a bare [GestureDetector] rather than the shared
/// [CopyIcon]: that one is an `IconButton` with a `Tooltip`, and neither is
/// safe to assume in an error widget.
class ErrorReportBlock extends StatelessWidget {
  /// Muted uppercase label above the block — `ERROR`, `STACK`.
  final String header;

  /// What the copy toast and share subject call this block.
  final String label;

  final String body;

  /// Colour of the block's text.
  final Color tone;

  const ErrorReportBlock({
    super.key,
    required this.header,
    required this.label,
    required this.body,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              header,
              style: monoStyle(
                size: 11,
                weight: FontWeight.w700,
                color: DebugColors.textMuted,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => copyAndShare(
                context,
                body,
                label: label,
                subject: DebugStrings.errorScreenShareSubject,
              ),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.copy, size: 16, color: DebugColors.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        CodeBlock(body, color: tone, selectable: false),
      ],
    );
  }
}
