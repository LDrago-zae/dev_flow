import 'package:flutter/material.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/presentation/widgets/task_item.dart';
import 'package:dev_flow/services/time_tracker_service.dart';

class QuickTodoList extends StatefulWidget {
  final List<Task> todos;
  final Function(Task) onTodoTap;
  final Function(Task)? onToggleComplete;
  final String Function(DateTime) formatDate;

  const QuickTodoList({
    super.key,
    required this.todos,
    required this.onTodoTap,
    this.onToggleComplete,
    required this.formatDate,
  });

  @override
  State<QuickTodoList> createState() => _QuickTodoListState();
}

class _QuickTodoListState extends State<QuickTodoList> {
  final _timeTracker = TimeTrackerService();
  String _timerDuration = '';

  @override
  void initState() {
    super.initState();
    _timeTracker.timerStream.listen((_) {
      if (mounted) {
        setState(() {
          _timerDuration = _timeTracker.formatDuration(
            _timeTracker.elapsedSeconds,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.todos.map((todo) {
        final isThisTaskActive = _timeTracker.activeEntry?.taskId == todo.id;
        return TaskItem(
          title: todo.title,
          subtitle: 'Quick Todo',
          date: widget.formatDate(todo.date),
          time: todo.time,
          isCompleted: todo.completed,
          onTap: () => widget.onTodoTap(todo),
          onCheckboxTap: widget.onToggleComplete != null
              ? () => widget.onToggleComplete!(todo)
              : null,
          onTimerTap: () async {
            if (isThisTaskActive) {
              await _timeTracker.stopTracking();
            } else {
              await _timeTracker.startTracking(taskId: todo.id);
            }
            setState(() {});
          },
          isTimerActive: isThisTaskActive,
          timerDuration: isThisTaskActive ? _timerDuration : null,
        );
      }).toList(),
    );
  }
}
