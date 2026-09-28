import 'package:flutter/material.dart';

import '../../domain/network_entry.dart';
import 'network_general_card.dart';
import '../../data/path_params.dart';
import '../../../../shared/debug_strings.dart';
import 'network_params_card.dart';

/// Overview tab layout: general card, query and path parameters.
class NetworkOverviewTab extends StatelessWidget {
  final NetworkEntry entry;
  final void Function(String text, String label) onCopy;

  const NetworkOverviewTab({
    super.key,
    required this.entry,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      children: [
        NetworkGeneralCard(entry: entry, onCopy: onCopy),
        NetworkParamsCard(
          title: DebugStrings.networkQueryParams,
          params: entry.queryParameters,
          onCopy: onCopy,
        ),
        NetworkParamsCard(
          title: DebugStrings.networkPathParams,
          params: PathParams.of(entry.url),
          onCopy: onCopy,
        ),
      ],
    );
  }
}
