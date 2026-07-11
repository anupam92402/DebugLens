import 'package:flutter/material.dart';

/// Confirmation dialog shown before deleting an activity. Returns `true` when
/// the user confirms. Pushed as a named [DialogRoute] so the DebugLens
/// navigation inspector records it as a `dialog` route kind.
class DeleteActivityDialog extends StatelessWidget {
  const DeleteActivityDialog({super.key, required this.title});

  final String title;

  static Future<bool?> show(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: 'home/delete-activity-dialog'),
      builder: (_) => DeleteActivityDialog(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete activity?'),
      content: Text('"$title" will be removed. This can\'t be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
