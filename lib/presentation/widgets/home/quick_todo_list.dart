import 'package:flutter/material.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/presentation/widgets/task_item.dart';

class QuickTodoList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: todos.map((todo) {
        return TaskItem(
          title: todo.title,
          subtitle: 'Quick Todo',
          date: formatDate(todo.date),
          time: todo.time,
          isCompleted: todo.completed,
          onTap: () => onTodoTap(todo),
          onCheckboxTap: onToggleComplete != null
              ? () => onToggleComplete!(todo)
              : null,
        );
      }).toList(),
    );
  }
}
