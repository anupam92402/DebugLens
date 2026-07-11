import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/activity.dart';
import '../bloc/home_bloc.dart';
import '../../../shell/presentation/cubit/shell_cubit.dart';
import 'category_style.dart';

/// Bottom sheet opened by the docked FAB to add a new activity.
class AddActivitySheet extends StatefulWidget {
  const AddActivitySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AddActivitySheet(),
    );
  }

  @override
  State<AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<AddActivitySheet> {
  final _titleController = TextEditingController();
  ActivityCategory _category = ActivityCategory.work;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    context.read<HomeBloc>().add(
      HomeActivityAdded(title: title, category: _category),
    );
    context.read<ShellCubit>().select(0); // jump back to Home to show it
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New activity',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'What do you want to do?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final category in ActivityCategory.values)
                ChoiceChip(
                  label: Text(category.label),
                  avatar: Icon(category.icon, size: 18, color: category.color),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add activity'),
            ),
          ),
        ],
      ),
    );
  }
}
