import 'package:flutter/material.dart';

import '../../domain/post.dart';

/// Displays a single [Post] passed via route arguments — the "next screen
/// built from GET data" (the post was fetched by the list, not refetched here).
class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Post #${post.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            post.title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'User ${post.userId}',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(post.body, style: textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}
