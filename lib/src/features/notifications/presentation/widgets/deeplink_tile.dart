import 'package:flutter/material.dart';
import '../../domain/deeplink_entry.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/theme/debug_theme.dart';
import '../../../../shared/widgets/debug_widgets.dart';
import '../../../../shared/widgets/json_view.dart';

class DeeplinkTile extends StatelessWidget {
  final DeeplinkEntry entry;

  const DeeplinkTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final uri = entry.parsed;
    return ExpansionTile(
      leading: const Icon(Icons.link),
      title: Text(
        entry.uri,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: monoStyle(size: 13),
      ),
      subtitle: Text(
        '${entry.source ?? DebugStrings.commonUnknown} · ${formatClock(entry.time)}',
        style: monoStyle(size: 11, color: DebugPalette.textMuted),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        KvRow(
          label: DebugStrings.deeplinksScheme,
          value: uri?.scheme ?? DebugConstants.emptyValue,
        ),
        KvRow(
          label: DebugStrings.deeplinksHost,
          value: uri?.host ?? DebugConstants.emptyValue,
        ),
        KvRow(
          label: DebugStrings.deeplinksPath,
          value: uri?.path ?? DebugConstants.emptyValue,
        ),
        const SizedBox(height: 8),
        if (entry.queryParameters.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              DebugStrings.deeplinksNoQueryParams,
              style: monoStyle(size: 12, color: DebugPalette.textMuted),
            ),
          )
        else
          JsonView(entry.queryParameters),
      ],
    );
  }
}
