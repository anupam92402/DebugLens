import 'package:flutter/material.dart';

import '../../domain/network_entry.dart';
import '../../data/http_status_codes.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';

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
            'Status: ${entry.isPending ? 'pending' : HttpStatusCodes.labelFor(entry.statusCode)}',
          )
          ..writeln('Request Time: ${entry.requestTime.toIso8601String()}')
          ..writeln(
            'Response Time: ${_responseTime?.toIso8601String() ?? DebugConstants.emptyValue}',
          )
          ..writeln(
            'Duration: ${entry.isPending ? DebugConstants.emptyValue : '${entry.durationMs ?? 0} ms'}',
          )
          ..writeln(
            'Content-Type: ${entry.contentType ?? DebugConstants.notAvailable}',
          )
          ..writeln(
            'Response-Type: ${entry.responseType ?? DebugConstants.notAvailable}',
          )
          ..writeln('Req size: ${entry.requestBytes ?? 0} B')
          ..writeln('Resp size: ${entry.responseBytes ?? 0} B'))
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: DebugStrings.networkGeneral,
      onCopy: () => onCopy(_asText(), DebugStrings.networkGeneral),
      child: Column(
        children: [
          KvRow(label: DebugStrings.networkLabelUrl, value: entry.url),
          KvRow(label: DebugStrings.networkLabelPath, value: entry.path),
          KvRow(
            label: DebugStrings.networkLabelMethod,
            value: entry.methodLabel,
          ),
          KvRow(
            label: DebugStrings.networkLabelStatus,
            value: entry.isPending
                ? DebugStrings.networkPending
                : HttpStatusCodes.labelFor(entry.statusCode),
          ),
          KvRow(
            label: DebugStrings.networkLabelRequestTime,
            value: entry.requestTime.toIso8601String(),
          ),
          KvRow(
            label: DebugStrings.networkLabelResponseTime,
            value:
                _responseTime?.toIso8601String() ?? DebugConstants.emptyValue,
          ),
          KvRow(
            label: DebugStrings.networkLabelDuration,
            value: entry.isPending
                ? DebugConstants.emptyValue
                : '${entry.durationMs ?? 0} ms',
          ),
          KvRow(
            label: DebugStrings.networkLabelContentType,
            value: entry.contentType ?? DebugConstants.notAvailable,
          ),
          KvRow(
            label: DebugStrings.networkLabelResponseType,
            value: entry.responseType ?? DebugConstants.notAvailable,
          ),
          KvRow(
            label: DebugStrings.networkLabelReqSize,
            value: '${entry.requestBytes ?? 0} B',
          ),
          KvRow(
            label: DebugStrings.networkLabelRespSize,
            value: '${entry.responseBytes ?? 0} B',
          ),
        ],
      ),
    );
  }
}
