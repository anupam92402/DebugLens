import 'package:flutter/material.dart';

import '../../domain/network_entry.dart';
import '../../../../shared/debug_strings.dart';
import 'network_headers_card.dart';

/// Headers tab layout: request headers, then response headers.
class NetworkHeadersTab extends StatelessWidget {
  final NetworkEntry entry;
  final void Function(String text, String label) onCopy;

  const NetworkHeadersTab({
    super.key,
    required this.entry,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      children: [
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
