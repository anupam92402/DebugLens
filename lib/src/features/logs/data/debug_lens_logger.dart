import 'package:flutter/foundation.dart';

import '../../storage/data/debug_shared_prefs_source.dart';
import '../../../shared/debug_constants.dart';
import '../../../shared/debug_strings.dart';
import '../../../core/debug_lens_config.dart';
import '../domain/log_origin.dart';
import '../domain/log_record.dart';

/// Signature for an external log observer — the hook for forwarding records
/// somewhere else, e.g. a crash reporter or your own server.
typedef DebugLogObserver =
    void Function(
      String message,
      DebugLogLevel level, {
      String? name,
      Object? error,
      StackTrace? stackTrace,
    });

/// The log store behind the Logs screen.
///
/// ## Purpose
///
/// One place for everything the app says, on-device, so you aren't tied to a
/// terminal. Records arrive two ways:
///
/// 1. **Your own calls** — [i] / [d] / [e].
/// 2. **DebugLens's own services** — the Dio interceptor, Bloc observer and
///    Navigator observer, each switchable at runtime from the Logs screen
///    (see [setCapturing]).
///
/// Framework and uncaught async errors aren't hooked for you — route them in
/// from your own `FlutterError.onError` / `PlatformDispatcher.onError` so you
/// stay in control of what DebugLens sees.
///
/// ## Usage
///
/// ```dart
/// DebugLensLogger.instance.i('Login succeeded', name: 'auth');
/// DebugLensLogger.instance.d('Fetched ${posts.length} posts', name: 'api');
/// DebugLensLogger.instance.e('Charge failed', name: 'payment', error: e, stackTrace: s);
/// ```
///
/// `name` becomes the `[tag]` on the row and what the screen's search matches.
/// Prefer a stable area name (`auth`, `api`, `checkout`) over a class name.
///
/// Terminal output is yours to control: [printToConsole] decides whether the
/// logger echoes each record through `debugPrint`. Set it from your own build
/// config, and turn it off when you already have a logger printing:
///
/// ```dart
/// DebugLensLogger.instance.printToConsole = kDebugMode; // or false
/// ```
///
/// Size the buffer once at startup ([defaultMaxHistory] records otherwise):
///
/// ```dart
/// DebugLensLogger.instance.maxHistory = 5000;
/// ```
///
/// Forward records elsewhere with [addLogObserver]. Extends [ChangeNotifier],
/// so the Logs screen rebuilds as records land.
class DebugLensLogger extends ChangeNotifier {
  DebugLensLogger._internal();

  /// Singleton accessor.
  static final DebugLensLogger instance = DebugLensLogger._internal();

  /// Whether records are echoed to the console. They are stored and shown
  /// either way; a single call overrides this with `force: true`.
  ///
  /// Yours to decide — wire it to your own build config rather than leaving it
  /// at the default, so DebugLens never silently changes what your terminal
  /// shows between builds:
  ///
  /// ```dart
  /// DebugLensLogger.instance.printToConsole = kDebugMode; // or a flavor flag
  /// ```
  bool printToConsole = true;

  /// Buffer size when the host hasn't set [maxHistory].
  static const int defaultMaxHistory = 1000;

  int _maxHistory = defaultMaxHistory;

  /// Cap on retained records, oldest dropped first. Lowering it trims now;
  /// values below 1 are ignored.
  int get maxHistory => _maxHistory;

  set maxHistory(int value) {
    assert(value > 0, 'maxHistory must be greater than 0, got $value');
    if (value < 1 || value == _maxHistory) return;
    _maxHistory = value;
    if (_trimToLimit()) notifyListeners();
  }

  /// The records themselves, oldest first — read via [history], capped by
  /// [maxHistory]. This is what the Logs screen renders and share exports.
  final List<DebugLogRecord> _history = [];

  /// Forwarders registered with [addLogObserver], invoked on every record.
  final List<DebugLogObserver> _onLog = [];

  /// Origins switched off in the capture sheet. Holding the *muted* ones keeps
  /// every origin on by default, including any added later.
  final Set<DebugLogOrigin> _mutedOrigins = <DebugLogOrigin>{};

  /// Whether [restoreCaptureSettings] has already run this session.
  bool _captureRestored = false;

  /// Recorded logs, oldest first.
  List<DebugLogRecord> get history => List.unmodifiable(_history);

  /// Whether records from [origin] are currently being recorded.
  bool isCapturing(DebugLogOrigin origin) => !_mutedOrigins.contains(origin);

  /// Starts or stops recording [origin], and persists the choice. Applies to
  /// new records only — rows already in [history] stay.
  void setCapturing(DebugLogOrigin origin, bool enabled) {
    final changed = enabled
        ? _mutedOrigins.remove(origin)
        : _mutedOrigins.add(origin);
    if (!changed) return;
    DebugLensSharedPrefs.setBool(origin.prefsKey, enabled);
    notifyListeners();
  }

  /// Reloads the persisted capture switches. `DebugLens.wrap()` calls this once
  /// — hosts don't need to, and it must not run before the binding exists.
  /// Only an explicit `false` mutes, so an untouched (or newly added) origin
  /// stays on; storage failures leave every origin recording.
  Future<void> restoreCaptureSettings() async {
    if (_captureRestored) return;
    _captureRestored = true;
    var changed = false;
    try {
      for (final origin in DebugLogOrigin.values) {
        if (await DebugLensSharedPrefs.getBool(origin.prefsKey) == false) {
          _mutedOrigins.add(origin);
          changed = true;
        }
      }
    } catch (_) {
      // Storage unavailable — defaults apply for this session.
    }
    if (changed) notifyListeners();
  }

  /// Registers a forwarder. Observers fire regardless of [printToConsole], so
  /// silencing the console never stops forwarding. Never call the logger from
  /// inside one — it recurses. Pair with [removeLogObserver].
  void addLogObserver(DebugLogObserver onLog) => _onLog.add(onLog);

  /// Removes an observer registered with [addLogObserver].
  void removeLogObserver(DebugLogObserver onLog) => _onLog.remove(onLog);

  /// Logs an info message.
  void i(String message, {String? name, bool force = false}) {
    _log(message, name: name, level: DebugLogLevel.info, force: force);
  }

  /// Logs an error message. Pass [error] / [stackTrace] for full context.
  void e(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    bool force = false,
  }) {
    _log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: DebugLogLevel.error,
      force: force,
    );
  }

  /// Logs a debug message.
  void d(String message, {String? name, bool force = false}) {
    _log(message, name: name, level: DebugLogLevel.debug, force: force);
  }

  /// Drops all retained records.
  void clear() {
    if (_history.isEmpty) return;
    _history.clear();
    notifyListeners();
  }

  void _log(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    required DebugLogLevel level,
    bool force = false,
  }) {
    final logBuffer = StringBuffer(DebugConstants.logTagPrefix);
    if (name?.isNotEmpty ?? false) logBuffer.write('-$name');
    final logName = logBuffer.toString();

    _append(
      DebugLogRecord(
        level: level,
        message: message,
        name: name,
        error: error,
        stackTrace: stackTrace?.toString(),
        time: DateTime.now(),
      ),
    );

    if (printToConsole || force) {
      final messageBuffer = StringBuffer()
        ..write('${level.paddedName} [$logName] $message');
      if (error != null) {
        messageBuffer.write('\n${DebugStrings.logsPrintError}: $error');
      }
      if (stackTrace != null) {
        messageBuffer.write('\n${DebugStrings.logsPrintStack}: $stackTrace');
      }
      debugPrint(messageBuffer.toString());
    }

    for (final observer in _onLog) {
      observer.call(
        message,
        level,
        name: logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _append(DebugLogRecord record) {
    // Console output is `printToConsole`'s business — this only skips keeping
    // the record, so the logger stays a usable facade when DebugLens is off.
    if (!DebugLensConfig.enabled) return;
    _history.add(record);
    _trimToLimit();
    notifyListeners();
  }

  /// Drops records above [maxHistory]; true if any went.
  bool _trimToLimit() {
    final excess = _history.length - _maxHistory;
    if (excess <= 0) return false;
    _history.removeRange(0, excess);
    return true;
  }
}
