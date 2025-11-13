import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/data/repositories/task_repository.dart';
import 'package:dev_flow/presentation/widgets/task_item.dart';
import 'package:dev_flow/presentation/dialogs/add_quick_todo_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'daily_task_detail_screen.dart';

class DailyTaskListScreen extends StatefulWidget {
  final bool isCompleted;
  final String title;
  final Color color;

  const DailyTaskListScreen({
    super.key,
    required this.isCompleted,
    required this.title,
    required this.color,
  });

  @override
  State<DailyTaskListScreen> createState() => _DailyTaskListScreenState();
}

class _DailyTaskListScreenState extends State<DailyTaskListScreen> {
  final TaskRepository _taskRepository = TaskRepository();
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final allTasks = await _taskRepository.getTasks(
          userId,
          projectId: null,
        );
        final filteredTasks = allTasks
            .where((task) => task.completed == widget.isCompleted)
            .toList();

        if (mounted) {
          setState(() {
            _tasks = filteredTasks;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    // Optimistically update UI
    final updatedTask = task.copyWith(completed: !task.completed);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      setState(() {
        _tasks[index] = updatedTask;
      });
    }

    try {
      await _taskRepository.updateTask(updatedTask);
    } catch (e) {
      // Revert on error
      if (index != -1) {
        setState(() {
          _tasks[index] = task;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update task: $e')));
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          AddQuickTodoDialog.show(
            context,
            onTodoCreated: (todo) async {
              try {
                await _taskRepository.createTask(todo);
                await _loadTasks();
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Quick todo created successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Failed to create todo: $e')),
                  );
                }
              }
            },
          );
        },
        backgroundColor: DarkThemeColors.primary100,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.grid_view_rounded,
                      color: Colors.blue[400],
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Task Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_tasks.length} Task${_tasks.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: DarkThemeColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tasks List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.blue[400]),
                    )
                  : _tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${widget.isCompleted ? 'completed' : 'incomplete'} tasks',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TaskItem(
                            title: task.title,
                            subtitle: 'Quick Todo',
                            date: _formatDate(task.date),
                            time: task.time,
                            isCompleted: task.completed,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DailyTaskDetailScreen(task: task),
                                ),
                              );
                              // Reload tasks if task was updated
                              if (result == true) {
                                _loadTasks();
                              }
                            },
                            onCheckboxTap: () => _toggleTaskCompletion(task),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
