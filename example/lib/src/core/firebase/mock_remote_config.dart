/// Where an active remote-config value came from.
enum RemoteConfigValueSource { defaultValue, remote }

/// In-memory stand-in for `FirebaseRemoteConfig`. Ships in-app defaults, then
/// [fetchAndActivate] overlays "server" values — the mechanism behind feature
/// flags and A/B experiments. Reads (`getBool`/`getString`/`getInt`) drive real
/// app behaviour; the DebugLens Firebase inspector shows the active values and
/// their source.
class MockRemoteConfig {
  MockRemoteConfig._() {
    _active.addAll(_defaults);
    for (final key in _defaults.keys) {
      _source[key] = RemoteConfigValueSource.defaultValue;
    }
  }
  static final MockRemoteConfig instance = MockRemoteConfig._();

  /// In-code defaults, used until (and if) a fetch overrides them.
  static const Map<String, Object> _defaults = {
    'home_header_title': 'Today',
    'show_summary_card': true,
    'promo_banner_text': '',
    'home_layout_experiment': 'control',
    'notification_batch_size': 6,
  };

  Map<String, Object> _server = const {};
  final Map<String, Object> _active = {};
  final Map<String, RemoteConfigValueSource> _source = {};

  DateTime? lastFetchTime;
  String lastFetchStatus = 'noFetchYet';

  /// Active values in key order, for the inspector.
  Map<String, Object> get all => Map.unmodifiable(_active);

  RemoteConfigValueSource sourceOf(String key) =>
      _source[key] ?? RemoteConfigValueSource.defaultValue;

  /// Registers the "server" values a fetch will activate (call before fetch).
  void setServerValues(Map<String, Object> server) => _server = server;

  /// Simulates a network fetch + activate: overlays the server values onto the
  /// active config and flags their source as remote.
  Future<bool> fetchAndActivate() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _server.forEach((key, value) {
      _active[key] = value;
      _source[key] = RemoteConfigValueSource.remote;
    });
    lastFetchTime = DateTime.now();
    lastFetchStatus = 'success';
    return true;
  }

  bool getBool(String key) =>
      _active[key] is bool ? _active[key] as bool : false;

  String getString(String key) => _active[key]?.toString() ?? '';

  int getInt(String key) =>
      _active[key] is num ? (_active[key] as num).toInt() : 0;
}
