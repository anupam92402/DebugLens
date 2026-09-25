import 'dart:convert';

/// Size ceilings for everything DebugLens keeps in memory.
///
/// Every feed is capped by *record count* (see `DebugLimits`), which bounds how
/// many things are kept but says nothing about how big each one is. A single
/// 1.5 MB API response, or a bloc state whose `toString()` dumps a whole model,
/// is enough to turn a 50-record cap into 150 MB of retained heap — so each
/// record is capped by size here as well.
///
/// The writer behind these helpers walks a value once, stops the moment the
/// budget is spent, and never materialises more than the budget. Measuring a
/// multi-megabyte payload therefore costs the budget, not the payload.
class PayloadBudget {
  PayloadBudget._();

  /// Largest request/response body DebugLens holds on to, in UTF-8 bytes.
  ///
  /// Under it, an entry keeps the decoded value itself, so the Network screen
  /// still renders a real object tree. Over it, the entry keeps a truncated
  /// text preview and lets the app's own copy be collected.
  static const int maxBodyBytes = 256 * 1024;

  /// Largest single stringified value DebugLens keeps — a bloc state, a log
  /// message, a stack trace, a navigation argument.
  static const int maxTextChars = 16 * 1024;

  /// Largest line DebugLens writes to the console.
  ///
  /// `debugPrint` drains a shared queue at roughly 12 KB per second and that
  /// queue has no ceiling, so anything logged faster than it drains piles up on
  /// the heap for as long as the app runs. The panel keeps the full record;
  /// the terminal only ever needs enough to recognise it by.
  static const int maxConsoleChars = 2 * 1024;

  /// Deepest structure the writer descends into. Guards deeply nested and
  /// self-referencing payloads.
  static const int _maxDepth = 64;

  /// Marker appended wherever content was dropped.
  static const String truncationMarker = '… [truncated by DebugLens]';

  /// [text] cut to [max] characters, with [truncationMarker] appended when
  /// anything was dropped. Returns [text] untouched when it already fits.
  static String clamp(String text, {int max = maxTextChars}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}$truncationMarker';
  }

  /// [clamp] over a nullable value; null stays null.
  static String? clampOrNull(String? text, {int max = maxTextChars}) =>
      text == null ? null : clamp(text, max: max);

  /// `value.toString()` clamped to [max]. The one place a foreign object is
  /// stringified for storage, so no single `toString()` can be retained whole.
  static String? describe(Object? value, {int max = maxTextChars}) =>
      value == null ? null : clamp(value.toString(), max: max);

  /// What [capture] decided about one body.
  ///
  /// [value] is what the entry should store: the original object when it fits,
  /// otherwise a truncated JSON preview. [bytes] is the payload's UTF-8 size —
  /// reported for oversized bodies too, since the writer keeps counting past
  /// the budget without keeping what it counted — or null when the value isn't
  /// JSON at all (a stream, a `FormData`, a live model).
  static ({Object? value, int? bytes}) capture(
    Object? body, {
    int max = maxBodyBytes,
  }) {
    if (body == null) return (value: null, bytes: null);

    // Raw bytes: the length is already known, and the list itself is both the
    // largest thing on the wire and unreadable in the viewer.
    if (body is List<int>) {
      if (body.length <= max) return (value: body, bytes: body.length);
      return (
        value: '<${body.length} bytes of binary body>$truncationMarker',
        bytes: body.length,
      );
    }

    final writer = _BudgetedJsonWriter(max, stringifyUnknown: false);
    writer.write(body);

    // Unencodable — a stream, a `FormData`, a live model. Keep a bounded
    // description instead of a reference into the app's object graph.
    if (writer.failed) return (value: describe(body), bytes: null);

    if (!writer.overflowed) return (value: body, bytes: writer.bytes);
    return (value: '${writer.text}$truncationMarker', bytes: writer.bytes);
  }

  /// Compact JSON for [body], never longer than [max] bytes. Non-JSON values
  /// fall back to their `toString()`, matching `jsonEncode`'s `toEncodable`.
  ///
  /// Used by the copy and share paths, which would otherwise build a full
  /// second copy of a payload in memory.
  static String encode(Object? body, {int max = maxBodyBytes}) {
    if (body == null) return 'null';
    final writer = _BudgetedJsonWriter(max, stringifyUnknown: true);
    writer.write(body);
    return writer.overflowed ? '${writer.text}$truncationMarker' : writer.text;
  }

  /// A budgeted deep copy of [value], decoupled from the app's live object
  /// graph so later mutation can't rewrite a recorded event.
  ///
  /// Falls back to a clamped string when the value is larger than [max] — a
  /// truncated tree isn't valid JSON, and text is more useful than nothing.
  static Object? snapshot(Object? value, {int max = maxBodyBytes}) {
    if (value == null) return null;
    final text = encode(value, max: max);
    try {
      return jsonDecode(text);
    } catch (_) {
      return clamp(text, max: max);
    }
  }
}

/// Writes the JSON form of a value into a buffer, and stops *writing* once
/// [maxBytes] UTF-8 bytes have gone in. It keeps walking after that so [bytes]
/// still reports the value's true size, but never allocates more than the
/// budget — so this is safe to run against a multi-megabyte payload.
class _BudgetedJsonWriter {
  _BudgetedJsonWriter(this.maxBytes, {required this.stringifyUnknown});

  final int maxBytes;

  /// Whether a value that isn't JSON renders as its `toString()` (true) or
  /// fails the whole write (false, so the caller can refuse to retain it).
  final bool stringifyUnknown;

  final StringBuffer _out = StringBuffer();

  /// The value's UTF-8 size. Counted in full, including the part past the
  /// budget that was never written.
  int bytes = 0;

  /// Whether the budget ran out before the value was fully written.
  bool overflowed = false;

  /// Whether the value can't be represented as JSON at all.
  bool failed = false;

  String get text => _out.toString();

  void write(Object? value) => _write(value, 0);

  void _write(Object? value, int depth) {
    if (failed) return;
    if (depth > PayloadBudget._maxDepth) {
      _emit('"<nested too deep>"');
      return;
    }
    if (value == null) {
      _emit('null');
    } else if (value is bool || value is num) {
      _emit('$value');
    } else if (value is String) {
      _emitString(value);
    } else if (value is List) {
      _emit('[');
      for (var i = 0; i < value.length; i++) {
        if (failed) return;
        if (i > 0) _emit(',');
        _write(value[i], depth + 1);
      }
      _emit(']');
    } else if (value is Map) {
      _emit('{');
      var first = true;
      for (final entry in value.entries) {
        if (failed) return;
        if (!first) _emit(',');
        first = false;
        _emitString('${entry.key}');
        _emit(':');
        _write(entry.value, depth + 1);
      }
      _emit('}');
    } else if (stringifyUnknown) {
      _emitString(value.toString());
    } else {
      failed = true;
    }
  }

  /// Encodes [value] as a JSON string, cutting it to what the budget can still
  /// hold *before* encoding, so a single huge leaf is never materialised whole.
  void _emitString(String value) {
    final room = maxBytes - bytes;
    // Past the budget: size it without building the escaped form. Quotes plus
    // the raw bytes, ignoring escapes — a size readout, not a byte count to
    // rebuild from.
    if (room <= 0) {
      bytes += _utf8Length(value) + 2;
      overflowed = true;
      return;
    }
    // A character is at least one UTF-8 byte, so `room` characters is always
    // enough to exhaust the remaining budget.
    if (value.length > room) {
      _emit(jsonEncode(value.substring(0, room)));
      bytes += _utf8Length(value) - _utf8Length(value.substring(0, room));
      overflowed = true;
      return;
    }
    _emit(jsonEncode(value));
  }

  void _emit(String chunk) {
    if (failed) return;
    final size = _utf8Length(chunk);
    bytes += size;
    if (overflowed) return;
    final room = maxBytes - (bytes - size);
    if (size > room) {
      if (room > 0) {
        _out.write(
          chunk.substring(0, room < chunk.length ? room : chunk.length),
        );
      }
      overflowed = true;
      return;
    }
    _out.write(chunk);
  }

  /// UTF-8 byte count that never builds the encoded bytes.
  static int _utf8Length(String s) {
    var total = 0;
    for (var i = 0; i < s.length; i++) {
      final unit = s.codeUnitAt(i);
      if (unit < 0x80) {
        total += 1;
      } else if (unit < 0x800) {
        total += 2;
      } else if (unit >= 0xD800 && unit < 0xDC00) {
        total += 4; // Surrogate pair.
        i++;
      } else {
        total += 3;
      }
    }
    return total;
  }
}
