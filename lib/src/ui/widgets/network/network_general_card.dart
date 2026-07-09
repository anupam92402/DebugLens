import 'package:flutter/material.dart';

import '../../../core/models/network_entry.dart';
import '../../../integration/http_status_codes.dart';
import '../debug_widgets.dart';

/// "General" SectionCard on the Network detail Overview tab. Hosts every
/// scalar field about the request — URL, method, status, timing, sizes,
/// content/response types.
///
/// Headers are intentionally NOT here — they live in a sibling card
/// (`NetworkHeadersCard` for request headers in Overview) so they can be
/// copied independently and don't bloat this one.
class NetworkGeneralCard extends StatelessWidget {
  final NetworkEntry entry;
  final void Function(String text, String label) onCopy;

  const NetworkGeneralCard({
    super.key,
    required this.entry,
    required this.onCopy,
  });

  /// Computed response time (request time + duration). Returns `null` while
  /// the request is in-flight. Derived, not stored, to keep [NetworkEntry]
  /// focused on what the interceptor actually captures.
  DateTime? get _responseTime {
    if (entry.durationMs == null) return null;
    return entry.requestTime.add(Duration(milliseconds: entry.durationMs!));
  }

  /// Plain-text rendering used by the COPY button on this card.
  String _asText() {
    return (StringBuffer()
          ..writeln('URL: ${entry.url}')
          ..writeln('Path: ${entry.path}')
          ..writeln('Method: ${entry.methodLabel}')
          ..writeln(
              'Status: ${entry.isPending ? 'pending' : HttpStatusCodes.labelFor(entry.statusCode)}')
          ..writeln('Request Time: ${entry.requestTime.toIso8601String()}')
          ..writeln(
              'Response Time: ${_responseTime?.toIso8601String() ?? '—'}')
          ..writeln(
              'Duration: ${entry.isPending ? '—' : '${entry.durationMs ?? 0} ms'}')
          ..writeln('Content-Type: ${entry.contentType ?? 'N/A'}')
          ..writeln('Response-Type: ${entry.responseType ?? 'N/A'}')
          ..writeln('Req size: ${entry.requestBytes ?? 0} B')
          ..writeln('Resp size: ${entry.responseBytes ?? 0} B'))
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'General',
      onCopy: () => onCopy(_asText(), 'General'),
      child: Column(
        children: [
          KvRow(label: 'URL', value: entry.url),
          KvRow(label: 'Path', value: entry.path),
          KvRow(label: 'Method', value: entry.methodLabel),
          KvRow(
            label: 'Status',
            value: entry.isPending
                ? 'pending'
                : HttpStatusCodes.labelFor(entry.statusCode),
          ),
          KvRow(
            label: 'Request Time',
            value: entry.requestTime.toIso8601String(),
          ),
          KvRow(
            label: 'Response Time',
            value: _responseTime?.toIso8601String() ?? '—',
          ),
          KvRow(
            label: 'Duration',
            value: entry.isPending ? '—' : '${entry.durationMs ?? 0} ms',
          ),
          KvRow(label: 'Content-Type', value: entry.contentType ?? 'N/A'),
          KvRow(label: 'Response-Type', value: entry.responseType ?? 'N/A'),
          KvRow(label: 'Req size', value: '${entry.requestBytes ?? 0} B'),
          KvRow(label: 'Resp size', value: '${entry.responseBytes ?? 0} B'),
        ],
      ),
    );
  }
}
