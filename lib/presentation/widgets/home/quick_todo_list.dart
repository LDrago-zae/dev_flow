import 'package:flutter/material.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/data/models/user_model.dart';
import 'package:dev_flow/presentation/widgets/task_item.dart';
import 'package:dev_flow/presentation/widgets/user_avatar.dart';

class QuickTodoList extends StatelessWidget {
  final List<Task> todos;
  final Function(Task) onTodoTap;
  final String Function(DateTime) formatDate;

  const QuickTodoList({
    super.key,
    required this.todos,
    required this.onTodoTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: todos.map((todo) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: TaskItem(
                  title: todo.title,
                  subtitle: 'Quick Todo',
                  date: formatDate(todo.date),
                  time: todo.time,
                  onTap: () => onTodoTap(todo),
                ),
              ),
              const SizedBox(width: 8),
              UserAvatar(
                user: todo.assignedUserId != null
                    ? DummyUsers.getUserById(todo.assignedUserId!)
                    : null,
                radius: 16,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
