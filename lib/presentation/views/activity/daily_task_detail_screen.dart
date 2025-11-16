import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/presentation/widgets/user_avatar.dart';
import 'package:dev_flow/data/models/user_model.dart';
import 'package:dev_flow/data/repositories/task_repository.dart';
import 'package:dev_flow/data/repositories/user_repository.dart';
import 'package:dev_flow/data/models/subtask_model.dart';
import 'package:dev_flow/data/repositories/subtask_repository.dart';
import 'package:dev_flow/presentation/widgets/project_details/subtask_list_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:uuid/uuid.dart';
import 'package:dev_flow/presentation/widgets/animated_fade_slide.dart';

class DailyTaskDetailScreen extends StatefulWidget {
  final Task task;

  const DailyTaskDetailScreen({super.key, required this.task});

  @override
  State<DailyTaskDetailScreen> createState() => _DailyTaskDetailScreenState();
}

class _DailyTaskDetailScreenState extends State<DailyTaskDetailScreen> {
  final TaskRepository _taskRepository = TaskRepository();
  final UserRepository _userRepository = UserRepository();
  final SubtaskRepository _subtaskRepository = SubtaskRepository();
  final TextEditingController _subtaskController = TextEditingController();
  late Task _currentTask;
  User? _assignedUser;
  bool _isLoadingUser = false;
  bool _isLoadingSubtasks = false;
  bool _isLoadingDependencies = false;
  List<Subtask> _subtasks = [];
  List<Task> _dependencyTasks = [];

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _loadAssignedUser();
    _loadSubtasks();
    _loadDependencies();
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignedUser() async {
    if (_currentTask.assignedUserId == null) return;

    setState(() => _isLoadingUser = true);
    try {
      final user = await _userRepository.getUserById(
        _currentTask.assignedUserId!,
      );
      if (mounted) {
        setState(() {
          _assignedUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  Future<void> _loadSubtasks() async {
    setState(() {
      _isLoadingSubtasks = true;
    });

    try {
      final subtasks = await _subtaskRepository.getSubtasks(_currentTask.id);
      if (mounted) {
        setState(() {
          _subtasks = subtasks;
          _isLoadingSubtasks = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSubtasks = false;
        });
      }
    }
  }

  Future<void> _addSubtask() async {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) {
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to be logged in to add subtasks.'),
          ),
        );
      }
      return;
    }

    final newSubtask = Subtask(
      id: const Uuid().v4(),
      parentTaskId: _currentTask.id,
      title: title,
      isCompleted: false,
      createdDate: DateTime.now(),
      ownerId: userId,
    );

    setState(() {
      _subtasks.add(newSubtask);
    });
    _subtaskController.clear();

    try {
      await _subtaskRepository.createSubtask(newSubtask);
    } catch (e) {
      if (mounted) {
        setState(() {
          _subtasks.removeWhere((s) => s.id == newSubtask.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add subtask: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleSubtaskFromDetail(
    String subtaskId,
    bool isCompleted,
  ) async {
    setState(() {
      final index = _subtasks.indexWhere((s) => s.id == subtaskId);
      if (index != -1) {
        _subtasks[index] = _subtasks[index].copyWith(isCompleted: isCompleted);
      }
    });

    try {
      await _subtaskRepository.toggleSubtaskCompletion(subtaskId, isCompleted);
    } catch (e) {
      if (mounted) {
        setState(() {
          final index = _subtasks.indexWhere((s) => s.id == subtaskId);
          if (index != -1) {
            _subtasks[index] = _subtasks[index].copyWith(
              isCompleted: !isCompleted,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update subtask: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSubtaskFromDetail(String subtaskId) async {
    Subtask? removed;

    setState(() {
      final index = _subtasks.indexWhere((s) => s.id == subtaskId);
      if (index != -1) {
        removed = _subtasks[index];
        _subtasks.removeAt(index);
      }
    });

    try {
      await _subtaskRepository.deleteSubtask(subtaskId);
    } catch (e) {
      if (mounted && removed != null) {
        setState(() {
          _subtasks.add(removed!);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete subtask: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadDependencies() async {
    if (_currentTask.dependencyIds.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingDependencies = true;
    });

    try {
      final tasks = await _taskRepository.getTasks(
        _currentTask.userId,
        projectId: _currentTask.projectId,
      );

      final deps = tasks
          .where((t) => _currentTask.dependencyIds.contains(t.id))
          .toList();

      if (mounted) {
        setState(() {
          _dependencyTasks = deps;
          _isLoadingDependencies = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingDependencies = false;
        });
      }
    }
  }

  Future<void> _editTask() async {
    final titleController = TextEditingController(text: _currentTask.title);
    DateTime selectedDate = _currentTask.date;
    TimeOfDay selectedTime = TimeOfDay(
      hour: int.parse(_currentTask.time.split(':')[0]),
      minute: int.parse(_currentTask.time.split(':')[1]),
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: DarkThemeColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Edit Task',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: TextStyle(
                        color: DarkThemeColors.textSecondary,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: DarkThemeColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: DarkThemeColors.primary100,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setModalState(() => selectedDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: DarkThemeColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: DarkThemeColors.primary100,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setModalState(() => selectedTime = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: DarkThemeColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: DarkThemeColors.primary100,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedTime.format(context),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a title'),
                            ),
                          );
                          return;
                        }
                        try {
                          final updatedTask = _currentTask.copyWith(
                            title: titleController.text,
                            date: selectedDate,
                            time:
                                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                          );
                          await _taskRepository.updateTask(updatedTask);
                          setState(() => _currentTask = updatedTask);
                          Navigator.pop(context, true);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Task updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DarkThemeColors.primary100,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Update Task',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
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
                  const Expanded(
                    child: Text(
                      'Task Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue[400]),
                    onPressed: _editTask,
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Task Detail Card
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Status Row
                      AnimatedFadeSlide(
                        delay: 0.0,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _currentTask.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  decoration: _currentTask.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _currentTask.completed
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _currentTask.completed
                                    ? 'Completed'
                                    : 'Pending',
                                style: TextStyle(
                                  color: _currentTask.completed
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Date Section
                      AnimatedFadeSlide(
                        delay: 0.1,
                        child: _buildDetailRow(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: _formatDate(_currentTask.date),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time Section
                      AnimatedFadeSlide(
                        delay: 0.15,
                        child: _buildDetailRow(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: _currentTask.time,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category
                      AnimatedFadeSlide(
                        delay: 0.2,
                        child: _buildDetailRow(
                          icon: Icons.category,
                          label: 'Category',
                          value: 'Quick Todo',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Dependencies
                      AnimatedFadeSlide(
                        delay: 0.25,
                        child: _buildDependenciesSection(),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      AnimatedFadeSlide(
                        delay: 0.3,
                        child: Divider(color: Colors.grey[800], height: 1),
                      ),
                      const SizedBox(height: 24),

                      // Assigned User Section
                      AnimatedFadeSlide(
                        delay: 0.35,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assigned to',
                              style: TextStyle(
                                color: DarkThemeColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _isLoadingUser
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                DarkThemeColors.primary100,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Loading user...',
                                        style: TextStyle(
                                          color: DarkThemeColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      UserAvatar(
                                        user: _assignedUser,
                                        radius: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      if (_assignedUser != null)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _assignedUser!.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              _assignedUser!.email,
                                              style: TextStyle(
                                                color: DarkThemeColors
                                                    .textSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Text(
                                          'Unassigned',
                                          style: TextStyle(
                                            color:
                                                DarkThemeColors.textSecondary,
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Subtasks
                      AnimatedFadeSlide(
                        delay: 0.4,
                        child: _buildSubtasksSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: DarkThemeColors.primary100),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: DarkThemeColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDependenciesSection() {
    if (_currentTask.dependencyIds.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isLoadingDependencies) {
      return Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                DarkThemeColors.primary100,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading dependencies...',
            style: TextStyle(
              color: DarkThemeColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    if (_dependencyTasks.isEmpty) {
      return Text(
        'Dependencies info not available',
        style: TextStyle(color: DarkThemeColors.textSecondary, fontSize: 14),
      );
    }

    final blockedTasks = _dependencyTasks.where((t) => !t.completed).toList();
    final isBlocked = blockedTasks.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dependencies',
          style: TextStyle(
            color: DarkThemeColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              isBlocked ? Icons.block : Icons.check_circle,
              size: 18,
              color: isBlocked ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isBlocked
                    ? 'Blocked by: ${blockedTasks.map((t) => t.title).join(', ')}'
                    : 'All dependencies completed',
                style: TextStyle(
                  color: DarkThemeColors.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: _dependencyTasks.map((t) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    t.completed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: t.completed
                        ? Colors.green
                        : DarkThemeColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.title,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubtasksSection() {
    final projectCardColor = DarkThemeColors.primary100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subtasks',
          style: TextStyle(
            color: DarkThemeColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _subtaskController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a subtask...',
                  hintStyle: TextStyle(
                    color: DarkThemeColors.textSecondary,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _addSubtask(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.send, size: 20, color: projectCardColor),
              onPressed: _addSubtask,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingSubtasks)
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DarkThemeColors.primary100,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading subtasks...',
                style: TextStyle(
                  color: DarkThemeColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          )
        else if (_subtasks.isEmpty)
          Text(
            'No subtasks yet',
            style: TextStyle(
              color: DarkThemeColors.textSecondary,
              fontSize: 14,
            ),
          )
        else
          SubtaskListWidget(
            subtasks: _subtasks,
            projectCardColor: projectCardColor,
            onToggleSubtask: _toggleSubtaskFromDetail,
            onDeleteSubtask: _deleteSubtaskFromDetail,
          ),
      ],
    );
  }
}
