import 'package:flutter/material.dart';

import '../../domain/config_editor.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Renders an editable-config service (e.g. Remote Config) as a list of typed
/// rows. When [editable] a row opens [onEdit] to override its value; otherwise
/// it opens [onView], which shows the source of truth read-only.
class ServiceConfigView extends StatelessWidget {
  final List<DebugLensConfigEntry> entries;
  final bool editable;
  final bool filtered;
  final void Function(DebugLensConfigEntry entry) onEdit;
  final void Function(DebugLensConfigEntry entry) onView;

  const ServiceConfigView({
    super.key,
    required this.entries,
    required this.editable,
    required this.filtered,
    required this.onEdit,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return filtered
          ? const EmptyState(
              icon: Icons.search_off,
              message: DebugStrings.commonNoMatches,
            )
          : const EmptyState(
              icon: Icons.tune,
              message: DebugStrings.serviceEmpty,
            );
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: DebugColors.border),
      itemBuilder: (_, i) {
        final e = entries[i];
        return ListTile(
          title: Row(
            children: [
              StatusChip(e.type.label, color: toneForConfigType(e.type)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: monoStyle(size: 13),
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  e.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: monoStyle(size: 12, color: DebugColors.textMuted),
                ),
              ),
              if (e.overridden) ...[
                const SizedBox(width: 8),
                StatusChip(
                  DebugStrings.serviceOverridden,
                  color: DebugColors.service,
                ),
              ],
            ],
          ),
          trailing: Icon(
            editable ? Icons.edit_outlined : Icons.chevron_right,
            size: 18,
          ),
          onTap: () => editable ? onEdit(e) : onView(e),
        );
      },
    );
  }
}
