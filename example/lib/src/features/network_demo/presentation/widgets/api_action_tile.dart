import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/api_action.dart';
import '../bloc/playground/playground_bloc.dart';

/// One quick-call row: method chip, title/subtitle, and a trailing control
/// reflecting the call's phase (idle / loading / success / error).
class ApiActionTile extends StatelessWidget {
  const ApiActionTile({super.key, required this.action});

  final ApiAction action;

  static const _methodColors = {
    'GET': Color(0xFF059669),
    'POST': Color(0xFF4F46E5),
    'PUT': Color(0xFFD97706),
    'DELETE': Color(0xFFDC2626),
  };

  @override
  Widget build(BuildContext context) {
    final color = _methodColors[action.methodLabel]!;
    final result = context.select<PlaygroundBloc, ActionResult>(
      (bloc) => bloc.state.resultFor(action),
    );
    return Card(
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            action.methodLabel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        title: Text(
          action.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(action.subtitle),
        trailing: _Trailing(result: result),
        onTap: result.phase == ActionPhase.loading
            ? null
            : () => context.read<PlaygroundBloc>().add(ApiActionRun(action)),
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({required this.result});

  final ActionResult result;

  @override
  Widget build(BuildContext context) {
    switch (result.phase) {
      case ActionPhase.loading:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ActionPhase.idle:
        return const Icon(Icons.play_circle_outline_rounded);
      case ActionPhase.success:
        return _Result(
          result.detail,
          const Color(0xFF059669),
          Icons.check_circle,
        );
      case ActionPhase.error:
        return _Result(result.detail, const Color(0xFFDC2626), Icons.error);
    }
  }
}

class _Result extends StatelessWidget {
  const _Result(this.detail, this.color, this.icon);

  final String detail;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, color: color, size: 20),
        ],
      ),
    );
  }
}
