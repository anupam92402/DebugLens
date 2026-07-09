enum NotificationKind { received, tapped }

class NotificationEntry {
  final String id;
  final String? title;
  final String? body;
  final Map<String, Object?> payload;
  final String source;
  final NotificationKind kind;
  final DateTime time;

  const NotificationEntry({
    required this.id,
    required this.time,
    this.title,
    this.body,
    this.payload = const {},
    this.source = 'FCM',
    this.kind = NotificationKind.received,
  });

  String get kindLabel =>
      kind == NotificationKind.tapped ? 'tapped' : 'received';
}
