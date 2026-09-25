import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:debug_lens/debug_lens.dart';
import 'package:debug_lens/src/core/debug_store.dart';
import 'package:debug_lens/src/shared/util/payload_budget.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bytes a captured value occupies, measured independently of the budget code
/// under test.
int sizeOf(Object? v) {
  if (v == null) return 0;
  try {
    return utf8.encode(jsonEncode(v)).length;
  } catch (_) {
    return utf8.encode(v.toString()).length;
  }
}

/// ~1.6 MB of JSON, the shape of a translations or master-data response.
Map<String, dynamic> bigPayload() => {
  for (var i = 0; i < 80; i++)
    'PREFIX_$i': {
      for (var k = 0; k < 200; k++)
        'KEY_${i}_$k':
            'Some reasonably long translated value $i/$k '
            'that looks like real app copy shown to a user.',
    },
};

class _BigState {
  _BigState(this.text);
  final String text;
  @override
  String toString() => text;
}

class _FakeBloc extends Cubit<int> {
  _FakeBloc() : super(0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const calls = 50;

  setUp(() {
    DebugLens.debugLensEnabled = true;
    DebugLens.initialLimits = const DebugLensLimits.all(calls);
    DebugLensLogger().printToConsole = false;
    DebugStore.instance.clearAll();
  });

  test('a full network feed stays within the per-body budget', () {
    final payload = bigPayload();
    expect(sizeOf(payload), greaterThan(PayloadBudget.maxBodyBytes));

    final interceptor = DebugLensDioInterceptor();
    for (var i = 0; i < calls; i++) {
      final options = RequestOptions(
        path: '/api/v1/lang/keys',
        method: 'POST',
        baseUrl: 'https://example.com',
        data: {'locale': 'en', 'timestamp': '0'},
        headers: {'Authorization': 'Bearer x'},
      );
      interceptor.onRequest(options, RequestInterceptorHandler());
      interceptor.onResponse(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          // A fresh decode per call, exactly like a response off the wire.
          data: jsonDecode(jsonEncode(payload)),
        ),
        ResponseInterceptorHandler(),
      );
    }

    final entries = DebugStore.instance.network;
    expect(entries.length, calls);

    var retained = 0;
    for (final e in entries) {
      final body = sizeOf(e.responseBody);
      expect(
        body,
        lessThanOrEqualTo(PayloadBudget.maxBodyBytes * 2),
        reason: 'no single entry may hold an unbounded response',
      );
      // The true size is still reported even though it was never retained.
      expect(e.responseBytes, greaterThan(PayloadBudget.maxBodyBytes));
      retained += body + sizeOf(e.requestBody) + sizeOf(e.curl);
    }

    // Unbudgeted this is calls * 1.6 MB, i.e. ~80 MB of retained payload.
    expect(retained, lessThan(calls * PayloadBudget.maxBodyBytes * 2));
  });

  test('a full bloc feed stays within the per-record budget', () async {
    final state = _BigState('STATE(${'x' * 400000})');
    final observer = DebugLensBlocObserver();
    final bloc = _FakeBloc();
    for (var i = 0; i < calls; i++) {
      observer.onChange(bloc, Change(currentState: state, nextState: state));
    }
    await Future<void>.delayed(Duration.zero);

    final events = DebugStore.instance.blocEvents;
    expect(events.length, calls);
    for (final e in events) {
      expect(
        e.currentState!.length,
        lessThanOrEqualTo(PayloadBudget.maxTextChars * 2),
      );
      expect(
        e.nextState!.length,
        lessThanOrEqualTo(PayloadBudget.maxTextChars * 2),
      );
    }

    for (final record in DebugLensLogger().history) {
      expect(
        record.message.length,
        lessThanOrEqualTo(PayloadBudget.maxTextChars * 2),
      );
    }
  });

  test('a log record never retains the thrown object', () {
    final payload = bigPayload();
    DebugLensLogger().e(
      'request failed',
      name: 'net',
      error: DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          data: payload,
        ),
      ),
    );
    final record = DebugLensLogger().history.last;
    expect(
      record.error,
      isA<String>(),
      reason: 'a DioException carries the whole decoded response',
    );
    expect(
      (record.error! as String).length,
      lessThanOrEqualTo(PayloadBudget.maxTextChars * 2),
    );
  });
}
