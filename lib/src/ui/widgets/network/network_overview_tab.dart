import 'package:flutter/material.dart';

import '../../../core/models/network_entry.dart';
import 'network_general_card.dart';
import 'network_headers_card.dart';
import 'network_query_card.dart';

/// Composes the Overview tab on the Network detail screen. Each block is
/// its own [SectionCard]-based widget so the children handle their own
/// formatting + copy logic — this widget is just the layout.
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
        // Structured per-row Request / Response header cards. The old inline
        // "Headers" block was removed — it just duplicated Request headers;
        // this card's COPY button already copies the whole block in one tap.
        NetworkHeadersCard(
          title: 'Request headers',
          headers: entry.requestHeaders,
          onCopy: onCopy,
        ),
        NetworkHeadersCard(
          title: 'Response headers',
          headers: entry.responseHeaders,
          onCopy: onCopy,
        ),
      ],
    );
  }
}
