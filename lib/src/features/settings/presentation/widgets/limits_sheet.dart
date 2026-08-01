import 'package:flutter/material.dart';

import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_colors.dart';
import '../../../../shared/widgets/debug_bottom_sheet.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/glass.dart';
import '../../data/debug_limits_store.dart';
import '../../domain/debug_limit.dart';
import 'limit_edit_dialog.dart';

/// Bottom sheet listing every retained feed and the cap it is trimmed to.
/// Tapping a row opens [showLimitEditDialog] to change it.
class LimitsSheet extends StatelessWidget {
  const LimitsSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showDebugBottomSheet<void>(context, builder: (_) => const LimitsSheet());

  @override
  Widget build(BuildContext context) {
    final limits = DebugLimits.instance;
    return GlassSurface(
      squareBottom: true,
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: limits,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DebugStrings.settingsLimits,
                      style: monoStyle(size: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DebugStrings.settingsLimitsHint(
                        DebugLimit.min,
                        DebugLimit.max,
                      ),
                      style: monoStyle(size: 11, color: DebugColors.textMuted),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: DebugLimit.values.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: DebugColors.border),
                  itemBuilder: (_, i) {
                    final limit = DebugLimit.values[i];
                    return ListTile(
                      dense: true,
                      title: Text(limit.label, style: monoStyle(size: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${limits.of(limit)}',
                            style: monoStyle(
                              size: 13,
                              color: limits.isCustom(limit)
                                  ? DebugColors.service
                                  : DebugColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit_outlined, size: 16),
                        ],
                      ),
                      onTap: () => showLimitEditDialog(context, limit),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
