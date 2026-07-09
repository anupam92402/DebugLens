/// A titled group of read-only key/value facts (e.g. "App", "Device").
class InfoSection {
  final String title;
  final Map<String, String> values;

  const InfoSection({required this.title, required this.values});
}
