import 'dart:convert';

import 'package:debug_lens/src/shared/util/payload_budget.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

int realSize(Object? v) => utf8.encode(jsonEncode(v)).length;

void main() {
  group('capture', () {
    test('keeps the value itself when it fits, with an exact byte count', () {
      final body = {
        'id': 7,
        'ok': true,
        'items': [1, 2.5, null, 'a'],
        'name': 'héllo — ünïcode',
      };
      final result = PayloadBudget.capture(body);
      expect(
        identical(result.value, body),
        isTrue,
        reason: 'a small body must stay renderable as an object tree',
      );
      expect(result.bytes, realSize(body));
    });

    test('replaces an oversized body with a bounded preview', () {
      final body = {for (var i = 0; i < 40000; i++) 'k$i': 'value number $i'};
      final full = realSize(body);
      expect(full, greaterThan(PayloadBudget.maxBodyBytes));

      final result = PayloadBudget.capture(body);
      expect(result.value, isA<String>());
      final kept = result.value as String;
      expect(kept, contains(PayloadBudget.truncationMarker));
      expect(
        utf8.encode(kept).length,
        lessThanOrEqualTo(
          PayloadBudget.maxBodyBytes +
              utf8.encode(PayloadBudget.truncationMarker).length,
        ),
        reason: 'the preview must never exceed the budget',
      );
      expect(kept, startsWith('{"k0":"value number 0"'));
      // The true size is still reported, though it was never materialised.
      expect(result.bytes, full);
    });

    test('a single huge string leaf is never materialised whole', () {
      final body = {'blob': 'x' * 5000000};
      final result = PayloadBudget.capture(body);
      final kept = result.value as String;
      expect(kept.length, lessThan(PayloadBudget.maxBodyBytes + 200));
      expect(result.bytes, greaterThan(5000000));
    });

    test('raw bytes report their length and are dropped when large', () {
      final small = List<int>.filled(100, 65);
      expect(identical(PayloadBudget.capture(small).value, small), isTrue);

      final large = List<int>.filled(2 * 1024 * 1024, 65);
      final result = PayloadBudget.capture(large);
      expect(result.value, isA<String>());
      expect(result.bytes, large.length);
    });

    test('FormData is described, never retained', () {
      final form = FormData.fromMap({'file': 'pretend-bytes'});
      final result = PayloadBudget.capture(form);
      expect(result.value, isA<String>());
      expect(result.value, isNot(same(form)));
      expect(result.bytes, isNull);
    });

    test('null stays null', () {
      expect(PayloadBudget.capture(null).value, isNull);
    });

    test('a self-referencing structure terminates', () {
      final loop = <String, Object?>{'a': 1};
      loop['self'] = loop;
      final result = PayloadBudget.capture(loop);
      expect(result.value, isNotNull);
    });
  });

  group('encode', () {
    test('matches jsonEncode when the value fits', () {
      final body = {
        'a': 1,
        'b': ['x', null, false],
      };
      expect(PayloadBudget.encode(body), jsonEncode(body));
    });

    test('stringifies values JSON cannot represent', () {
      final encoded = PayloadBudget.encode({'when': DateTime(2020, 1, 2)});
      expect(encoded, contains('2020-01-02'));
    });

    test('never exceeds the requested budget', () {
      final body = {for (var i = 0; i < 40000; i++) 'k$i': 'value $i'};
      final encoded = PayloadBudget.encode(body, max: 1024);
      expect(
        utf8.encode(encoded).length,
        lessThanOrEqualTo(
          1024 + utf8.encode(PayloadBudget.truncationMarker).length,
        ),
      );
    });
  });

  group('clamp and describe', () {
    test('short text passes through untouched', () {
      expect(PayloadBudget.clamp('hello'), 'hello');
      expect(PayloadBudget.describe(null), isNull);
    });

    test('long text is cut and marked', () {
      final out = PayloadBudget.clamp('y' * 100000);
      expect(
        out.length,
        PayloadBudget.maxTextChars + PayloadBudget.truncationMarker.length,
      );
      expect(out, endsWith(PayloadBudget.truncationMarker));
    });
  });

  group('snapshot', () {
    test('deep-copies, decoupling from the caller', () {
      final live = <String, Object?>{
        'n': 1,
        'list': [1, 2],
      };
      final snap = PayloadBudget.snapshot(live) as Map<String, dynamic>;
      live['n'] = 999;
      (live['list'] as List).add(3);
      expect(snap['n'], 1);
      expect(snap['list'], [1, 2]);
    });

    test('falls back to text when the value overruns the budget', () {
      final big = {for (var i = 0; i < 5000; i++) 'k$i': 'v$i'};
      final snap = PayloadBudget.snapshot(big, max: 512);
      expect(snap, isA<String>());
      expect(snap as String, contains(PayloadBudget.truncationMarker));
    });
  });
}
