import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/data/models/user_model.dart';
import 'package:dev_flow/presentation/widgets/user_avatar.dart';
import 'package:dev_flow/presentation/widgets/user_dropdown.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dev_flow/data/repositories/task_repository.dart';
import 'package:dev_flow/services/realtime_service.dart';
import 'dart:async';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;
  final Function(Project) onUpdate;

  const ProjectDetailsScreen({
    super.key,
    required this.project,
    required this.onUpdate,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  late Project _project;
  String _selectedTab = 'All Task';
  late List<Task> _filteredTasks;
  final TextEditingController _taskTitleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isEditing = false;
  Task? _editingTask;
  String? _selectedTaskUserId;
  String? _selectedProjectUserId;

  // Supabase integration
  final TaskRepository _taskRepository = TaskRepository();
  final RealtimeService _realtimeService = RealtimeService();
  late StreamSubscription<Task> _taskSubscription;
  late StreamSubscription<Project> _projectSubscription;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _selectedProjectUserId = widget.project.assignedUserId;
    _updateFilteredTasks();
    _setupRealtimeSubscriptions();
    _loadProjectData();
  }

  void _setupRealtimeSubscriptions() {
    // Subscribe to project updates
    _realtimeService.subscribeToUserProjects(_project.userId);
    _projectSubscription = _realtimeService.projectUpdates.listen((
      updatedProject,
    ) {
      if (updatedProject.id == _project.id) {
        setState(() {
          _project = updatedProject;
          _updateFilteredTasks();
        });
      }
    });

    // Subscribe to project task updates
    _realtimeService.subscribeToProjectTasks(_project.id);
    _taskSubscription = _realtimeService.taskUpdates.listen((updatedTask) {
      setState(() {
        // Update task in project
        final updatedTasks = _project.tasks.map((task) {
          return task.id == updatedTask.id ? updatedTask : task;
        }).toList();

        _project = _project.copyWith(tasks: updatedTasks);
        _updateFilteredTasks();
      });
    });
  }

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final tasks = await _taskRepository.getTasks(
        userId,
        projectId: _project.id,
      );

      setState(() {
        _project = _project.copyWith(tasks: tasks);
        _updateFilteredTasks();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskSubscription.cancel();
    _projectSubscription.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  void _updateFilteredTasks() {
    setState(() {
      switch (_selectedTab) {
        case 'Ongoing':
          _filteredTasks = _project.tasks
              .where((task) => !task.isCompleted)
              .toList();
          break;
        case 'Completed':
          _filteredTasks = _project.tasks
              .where((task) => task.isCompleted)
              .toList();
          break;
        default:
          _filteredTasks = _project.tasks;
      }
    });
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

  Color _getPriorityColor(ProjectPriority priority) {
    switch (priority) {
      case ProjectPriority.high:
        return Colors.red;
      case ProjectPriority.medium:
        return Colors.orange;
      case ProjectPriority.low:
        return Colors.green;
    }
  }

  String _getPriorityText(ProjectPriority priority) {
    switch (priority) {
      case ProjectPriority.high:
        return 'High';
      case ProjectPriority.medium:
        return 'Medium';
      case ProjectPriority.low:
        return 'Low';
    }
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.ongoing:
        return Colors.green;
      case ProjectStatus.completed:
        return Colors.blue;
      case ProjectStatus.onHold:
        return Colors.orange;
    }
  }

  String _getStatusText(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.ongoing:
        return 'Ongoing';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.onHold:
        return 'On Hold';
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    // Optimistic update - immediately update UI
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    _optimisticUpdateTask(updatedTask);

    try {
      await _taskRepository.updateTask(updatedTask);
      // Real-time subscription will handle the final update
    } catch (e) {
      // Revert on error
      _optimisticUpdateTask(task);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update task: $e')));
      }
    }
  }

  void _optimisticUpdateTask(Task updatedTask) {
    setState(() {
      final updatedTasks = _project.tasks.map((t) {
        if (t.id == updatedTask.id) {
          return updatedTask;
        }
        return t;
      }).toList();

      final completedCount = updatedTasks.where((t) => t.isCompleted).length;
      final newProgress = updatedTasks.isEmpty
          ? 0.0
          : completedCount / updatedTasks.length;

      _project = _project.copyWith(tasks: updatedTasks, progress: newProgress);
      widget.onUpdate(_project);
      _updateFilteredTasks();
    });
  }

  Future<void> _addOrUpdateTask() async {
    if (_taskTitleController.text.trim().isEmpty) {
      return;
    }

    try {
      if (_isEditing && _editingTask != null) {
        // Edit existing task
        final updatedTask = _editingTask!.copyWith(
          title: _taskTitleController.text.trim(),
          date: _selectedDate,
          time:
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          assignedUserId: _selectedTaskUserId,
        );

        await _taskRepository.updateTask(updatedTask);
        // Real-time subscription will update UI
      } else {
        // Add new task
        final newTask = Task(
          id: const Uuid().v4(),
          title: _taskTitleController.text.trim(),
          date: _selectedDate,
          time:
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          isCompleted: false,
          assignedUserId: _selectedTaskUserId,
          projectId: _project.id,
          userId: Supabase.instance.client.auth.currentUser?.id ?? '',
        );

        await _taskRepository.createTask(newTask);
        // Real-time subscription will update UI
      }

      _resetDialogState();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save task: $e')));
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _taskRepository.deleteTask(task.id);
      // Real-time subscription will update UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete task: $e')));
      }
    }
  }

  void _assignProjectUser(String? userId) {
    setState(() {
      _selectedProjectUserId = userId;
      _project = _project.copyWith(assignedUserId: userId);
      widget.onUpdate(_project);
    });
  }

  void _resetDialogState() {
    _taskTitleController.clear();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _isEditing = false;
    _editingTask = null;
    _selectedTaskUserId = null;
  }

  void _showEditTaskDialog(Task task) {
    _isEditing = true;
    _editingTask = task;
    _taskTitleController.text = task.title;
    _selectedDate = task.date;
    _selectedTaskUserId = task.assignedUserId;

    // Parse time from string - handle multiple possible formats
    _selectedTime = _parseTimeString(task.time);

    _showTaskDialog();
  }

  TimeOfDay _parseTimeString(String timeString) {
    try {
      // Try HH:MM format first (e.g., "14:30")
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute =
              int.tryParse(parts[1].split(' ').first) ??
              0; // Handle "30 AM" case
          return TimeOfDay(hour: hour, minute: minute);
        }
      }

      // Try 12-hour format (e.g., "2:30 PM")
      final timeRegex = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)?',
        caseSensitive: false,
      );
      final match = timeRegex.firstMatch(timeString);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3)?.toUpperCase();

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return TimeOfDay(hour: hour, minute: minute);
      }

      // Fallback: just try to extract numbers
      final numberRegex = RegExp(r'\d+');
      final numbers = numberRegex
          .allMatches(timeString)
          .map((m) => int.tryParse(m.group(0)!))
          .whereType<int>()
          .toList();

      if (numbers.length >= 2) {
        return TimeOfDay(hour: numbers[0], minute: numbers[1]);
      } else if (numbers.length == 1) {
        return TimeOfDay(hour: numbers[0], minute: 0);
      }
    } catch (e) {
      debugPrint('Error parsing time: $timeString, error: $e');
    }

    // Ultimate fallback
    return TimeOfDay.now();
  }

  void _showTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: DarkThemeColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing ? 'Edit Task' : 'Add New Task',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _taskTitleController,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: DarkThemeColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Task title',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: DarkThemeColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: DarkThemeColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  UserDropdown(
                    selectedUserId: _selectedTaskUserId,
                    onUserSelected: (userId) {
                      setModalState(() {
                        _selectedTaskUserId = userId;
                      });
                    },
                    hintText: 'Assign task to user',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setModalState(() {
                                _selectedDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: DarkThemeColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: DarkThemeColors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: DarkThemeColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (time != null) {
                              setModalState(() {
                                _selectedTime = time;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: DarkThemeColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: DarkThemeColors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: DarkThemeColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addOrUpdateTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DarkThemeColors.primary100,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Update Task' : 'Add Task',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: DarkThemeColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: DarkThemeColors.primary100),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: DarkThemeColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: DarkThemeColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load project',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: DarkThemeColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: DarkThemeColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProjectData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DarkThemeColors.primary100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DarkThemeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Image Header
                    _buildProjectImage(),

                    // Project Info Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Created Date
                          Text(
                            '${_formatDate(_project.createdDate)} (created)',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: DarkThemeColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Title
                          Text(
                            _project.title,
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: DarkThemeColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          Text(
                            _project.description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: DarkThemeColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Status and Deadline Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: DarkThemeColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          _project.status,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _getStatusColor(
                                            _project.status,
                                          ).withOpacity(0.5),
                                        ),
                                      ),
                                      child: Text(
                                        _getStatusText(_project.status),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: _getStatusColor(
                                            _project.status,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Deadline',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: DarkThemeColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: DarkThemeColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _project.deadline,
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color:
                                                    DarkThemeColors.textPrimary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Assigned User Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned User',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: DarkThemeColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              UserDropdown(
                                selectedUserId: _selectedProjectUserId,
                                onUserSelected: _assignProjectUser,
                                hintText: 'Assign project to user',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Progress Section
                          _buildProgressSection(),
                          const SizedBox(height: 24),

                          // Task Tabs
                          _buildTaskTabs(),
                          const SizedBox(height: 16),

                          // Task List
                          _buildTaskList(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _resetDialogState();
          _showTaskDialog();
        },
        backgroundColor: DarkThemeColors.primary100,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Project Details',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show menu
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectImage() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(color: DarkThemeColors.surface),
          child: _project.imagePath != null
              ? Image.asset(
                  _project.imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: _project.cardColor.withOpacity(0.3),
                      child: Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: DarkThemeColors.textSecondary,
                      ),
                    );
                  },
                )
              : Container(
                  color: _project.cardColor.withOpacity(0.3),
                  child: Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: DarkThemeColors.textSecondary,
                  ),
                ),
        ),
        // Priority Badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getPriorityColor(_project.priority),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getPriorityText(_project.priority),
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ),
        // Edit Icon
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DarkThemeColors.primary100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: AppTextStyles.bodyMedium.copyWith(
            color: DarkThemeColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: DarkThemeColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final completedWidth =
                        constraints.maxWidth * _project.progress;
                    return Row(
                      children: [
                        Container(
                          width: completedWidth,
                          decoration: BoxDecoration(
                            color: _project.cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        Expanded(
                          child: Container(color: DarkThemeColors.border),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_project.completedTasksCount}/${_project.totalTasksCount} Task',
              style: AppTextStyles.bodyMedium.copyWith(
                color: DarkThemeColors.textSecondary,
              ),
            ),
            Text(
              '${(_project.progress * 100).toInt()}%',
              style: AppTextStyles.bodyMedium.copyWith(
                color: DarkThemeColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskTabs() {
    final tabs = ['All Task', 'Ongoing', 'Completed'];
    return Row(
      children: tabs.map((tab) {
        final isSelected = _selectedTab == tab;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTab = tab;
                _updateFilteredTasks();
              });
            },
            child: Column(
              children: [
                Text(
                  tab,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected
                        ? DarkThemeColors.primary100
                        : DarkThemeColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? DarkThemeColors.primary100
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskList() {
    if (_filteredTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No tasks found',
            style: AppTextStyles.bodyMedium.copyWith(
              color: DarkThemeColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _filteredTasks.map((task) {
        return _buildTaskItem(task);
      }).toList(),
    );
  }

  Widget _buildTaskItem(Task task) {
    String monthName;
    switch (task.date.month) {
      case 1:
        monthName = 'January';
        break;
      case 2:
        monthName = 'February';
        break;
      case 3:
        monthName = 'March';
        break;
      case 4:
        monthName = 'April';
        break;
      case 5:
        monthName = 'May';
        break;
      case 6:
        monthName = 'June';
        break;
      case 7:
        monthName = 'July';
        break;
      case 8:
        monthName = 'August';
        break;
      case 9:
        monthName = 'September';
        break;
      case 10:
        monthName = 'October';
        break;
      case 11:
        monthName = 'November';
        break;
      case 12:
        monthName = 'December';
        break;
      default:
        monthName = '';
    }

    final dateString = '${monthName} ${task.date.day}, ${task.date.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (direction) {
          _deleteTask(task);
        },
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleTaskCompletion(task),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.isCompleted
                        ? _project.cardColor
                        : DarkThemeColors.border,
                    width: 2,
                  ),
                  color: task.isCompleted
                      ? _project.cardColor
                      : Colors.transparent,
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: task.isCompleted
                          ? DarkThemeColors.textSecondary
                          : DarkThemeColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        dateString,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: DarkThemeColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'at',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: DarkThemeColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task.time,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: DarkThemeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.edit,
                size: 20,
                color: DarkThemeColors.textSecondary,
              ),
              onPressed: () => _showEditTaskDialog(task),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            UserAvatar(
              user: task.assignedUserId != null
                  ? DummyUsers.getUserById(task.assignedUserId!)
                  : null,
              radius: 16,
            ),
          ],
        ),
      ),
    );
  }
}
