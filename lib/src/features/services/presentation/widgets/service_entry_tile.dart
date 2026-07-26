import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/service_group.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_toast.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/json_view.dart';
import '../../../../shared/widgets/sequence_badge.dart';
import '../../../../shared/theme/debug_colors.dart';

/// Expandable row for one service record (an analytics event, a screen load,
/// a crash report, …), styled like the Navigation event rows: a position
/// badge, the record's primary label + optional subtitle, expanding to its
/// fields in a monospace box (like the Network body) with a single copy.
///
/// Fields the host marked sensitive stay masked unless [revealSensitive].
class ServiceEntryTile extends StatelessWidget {
  final int number;
  final DebugLensServiceGroup group;
  final bool revealSensitive;

  const ServiceEntryTile({
    super.key,
    required this.number,
    required this.group,
    this.revealSensitive = false,
  });

  /// The record as one JSON object. Fields are nested under `fields` rather
  /// than spread alongside `name`, so a record that happens to have its own
  /// `name` field can't shadow the record's title.
  Map<String, Object?> get _record => {
    'name': group.title,
    if (group.subtitle != null) 'subtitle': group.subtitle,
    'fields': revealSensitive ? group.values : group.maskedValues,
  };

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: prettyJson(_record)));
    DebugToast.show(context, DebugStrings.commonFieldCopied(group.title));
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: SequenceBadge('#$number'),
      title: Text(
        group.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: monoStyle(size: 13),
      ),
      subtitle: group.subtitle == null
          ? null
          : Text(
              group.subtitle!,
              style: monoStyle(size: 11, color: DebugColors.textMuted),
            ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: CopyIcon(
            tooltip: DebugStrings.commonCopyField(group.title),
            onTap: () => _copy(context),
          ),
        ),
        JsonView(_record),
      ],
    );
  }
}
