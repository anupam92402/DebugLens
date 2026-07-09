class DeeplinkEntry {
  final String id;
  final String uri;
  final DateTime time;
  final String? source;

  const DeeplinkEntry({
    required this.id,
    required this.uri,
    required this.time,
    this.source,
  });

  Uri? get parsed {
    try {
      return Uri.parse(uri);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> get queryParameters =>
      parsed?.queryParameters ?? const {};
}
