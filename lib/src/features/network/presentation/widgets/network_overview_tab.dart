import 'package:flutter/material.dart';

import '../../domain/network_entry.dart';
import '../../../../shared/debug_strings.dart';
import 'network_general_card.dart';
import 'network_headers_card.dart';
import 'network_query_card.dart';

/// Overview tab layout: general card, query, and request/response headers.
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
        NetworkQueryCard(
          queryParameters: entry.queryParameters,
          onCopy: onCopy,
        ),
        NetworkHeadersCard(
          title: DebugStrings.networkRequestHeaders,
          headers: entry.requestHeaders,
          onCopy: onCopy,
        ),
        NetworkHeadersCard(
          title: DebugStrings.networkResponseHeaders,
          headers: entry.responseHeaders,
          onCopy: onCopy,
        ),
      ],
    );
  }
}
