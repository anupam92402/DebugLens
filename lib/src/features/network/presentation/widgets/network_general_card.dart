import 'package:flutter/material.dart';

import '../../domain/network_entry.dart';
import '../../data/http_status_codes.dart';
import '../../../../shared/debug_constants.dart';
import '../../../../shared/debug_strings.dart';
import '../../../../shared/widgets/debug_widgets.dart';

/// "General" SectionCard on the detail Overview tab: every scalar field
/// (URL, method, status, timing, sizes, content/response types). Headers
/// live in sibling cards.
class NetworkGeneralCard extends StatelessWidget {
  final NetworkEntry entry;
  final void Function(String text, String label) onCopy;

  const NetworkGeneralCard({
    super.key,
    required this.entry,
    required this.onCopy,
  });

  /// Response time (request time + duration); null while in-flight.
  DateTime? get _responseTime {
    if (entry.durationMs == null) return null;
    return entry.requestTime.add(Duration(milliseconds: entry.durationMs!));
  }

  /// Plain-text rendering for this card's COPY button.
  String _asText() {
    return (StringBuffer()
          ..writeln('URL: ${entry.url}')
          ..writeln('Path: ${entry.path}')
          ..writeln('Method: ${entry.methodLabel}')
          ..writeln(
            'Status: ${entry.isPending ? 'pending' : HttpStatusCodes.labelFor(entry.statusCode)}',
          )
          ..writeln('Request Time: ${ClockFormat.dateTime(entry.requestTime)}')
          ..writeln(
            'Response Time: ${_responseTime == null ? DebugConstants.emptyValue : ClockFormat.dateTime(_responseTime!)}',
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
            value: ClockFormat.dateTime(entry.requestTime),
          ),
          KvRow(
            label: DebugStrings.networkLabelResponseTime,
            value: _responseTime == null
                ? DebugConstants.emptyValue
                : ClockFormat.dateTime(_responseTime!),
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
