import 'package:flutter/material.dart';

/// Destination opened when a local notification is tapped — shows the route
/// it deep-linked to and the payload it carried.
class NotificationLandingScreen extends StatelessWidget {
  const NotificationLandingScreen({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final route = data['route']?.toString() ?? '—';
    final title = data['title']?.toString();
    final body = data['body']?.toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (title != null)
            Card(
              child: ListTile(
                title: Text(title),
                subtitle: body == null ? null : Text(body),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Payload',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final entry in data.entries)
                  ListTile(
                    dense: true,
                    title: Text(entry.key),
                    trailing: Text('${entry.value}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
