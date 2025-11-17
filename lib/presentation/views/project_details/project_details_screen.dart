import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/data/models/subtask_model.dart';
import 'package:dev_flow/data/models/user_model.dart';
import 'package:dev_flow/presentation/widgets/user_avatar.dart';
import 'package:dev_flow/presentation/widgets/user_dropdown.dart';
import 'package:dev_flow/presentation/dialogs/add_edit_task_dialog.dart';
import 'package:dev_flow/presentation/widgets/task_location_map_card.dart';
import 'package:dev_flow/presentation/views/task_location_map_screen.dart';
import 'package:dev_flow/presentation/widgets/project_details/kanban_board_widget.dart';
import 'package:dev_flow/presentation/widgets/project_member_avatars.dart';
import 'package:dev_flow/presentation/dialogs/manage_members_dialog.dart';
import 'package:dev_flow/presentation/dialogs/project_attachments_dialog.dart';
import 'package:dev_flow/presentation/widgets/animated_fade_slide.dart';
import 'package:dev_flow/presentation/widgets/project_details/project_details_app_bar.dart';
import 'package:dev_flow/presentation/widgets/project_details/project_image_header.dart';
import 'package:dev_flow/presentation/widgets/project_details/project_progress_section.dart';
import 'package:dev_flow/presentation/widgets/project_details/task_tabs_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dev_flow/data/repositories/offline_task_repository.dart';
import 'package:dev_flow/data/repositories/subtask_repository.dart';
import 'package:dev_flow/data/repositories/offline_project_repository.dart';
import 'package:dev_flow/data/repositories/shared_items_repository.dart';
import 'package:dev_flow/data/repositories/project_members_repository.dart';
import 'package:dev_flow/services/realtime_service.dart';
import 'package:dev_flow/services/fcm_service.dart';
import 'package:dev_flow/services/notification_service.dart';
import 'package:dev_flow/services/time_tracker_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';

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
  bool _isKanbanView = false;
  final TextEditingController _taskTitleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isEditing = false;
  Task? _editingTask;
  String? _selectedTaskUserId;
  String? _selectedProjectUserId;

  // Data layer (offline-first repositories)
  final OfflineTaskRepository _taskRepository = OfflineTaskRepository();
  final SubtaskRepository _subtaskRepository = SubtaskRepository();
  final OfflineProjectRepository _projectRepository =
      OfflineProjectRepository();
  final SharedItemsRepository _sharedItemsRepository = SharedItemsRepository();
  final RealtimeService _realtimeService = RealtimeService();
  final ImagePicker _imagePicker = ImagePicker();
  late StreamSubscription<Task> _taskSubscription;
  late StreamSubscription<Project> _projectSubscription;

  // Subtask management
  Map<String, List<Subtask>> _taskSubtasks = {};
  Map<String, StreamSubscription<List<Subtask>>> _subtaskSubscriptions = {};
  final TextEditingController _subtaskController = TextEditingController();
  String? _addingSubtaskFor; // Track which task is having a subtask added
  String? _expandedTaskId; // Track which task is expanded to show details

  // Time tracking
  final _timeTracker = TimeTrackerService();
  String _timerDuration = '';

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

    // Listen to timer updates
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

      // Fetch complete project data from database including image_path and assigned_user_id
      final updatedProject = await _projectRepository.getProjectById(
        _project.id,
      );

      setState(() {
        _project = updatedProject;
        _selectedProjectUserId = updatedProject.assignedUserId;
        _updateFilteredTasks();
        _isLoading = false;
      });

      // Load subtasks for each task
      await _loadSubtasksForAllTasks();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createNextRecurringTask(Task baseTask) async {
    final pattern = baseTask.recurrencePattern;
    if (pattern == null || pattern.isEmpty) return;

    DateTime nextDate;
    switch (pattern) {
      case 'daily':
        nextDate = baseTask.date.add(const Duration(days: 1));
        break;
      case 'weekdays':
        nextDate = baseTask.date.add(const Duration(days: 1));
        while (nextDate.weekday == DateTime.saturday ||
            nextDate.weekday == DateTime.sunday) {
          nextDate = nextDate.add(const Duration(days: 1));
        }
        break;
      case 'weekly':
        nextDate = baseTask.date.add(const Duration(days: 7));
        break;
      case 'monthly':
        nextDate = DateTime(
          baseTask.date.year,
          baseTask.date.month + 1,
          baseTask.date.day,
        );
        break;
      case 'yearly':
        nextDate = DateTime(
          baseTask.date.year + 1,
          baseTask.date.month,
          baseTask.date.day,
        );
        break;
      default:
        return;
    }

    final nextTask = baseTask.copyWith(
      id: const Uuid().v4(),
      date: nextDate,
      isCompleted: false,
      completed: false,
      completedAt: null,
      clearCompletedAt: true,
    );

    try {
      await _taskRepository.createTask(nextTask);
    } catch (_) {
      // If creating the next recurrence fails, we silently ignore for now
    }
  }

  Future<void> _addTemplateTasksToProject(String templateKey) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now();
    final List<Map<String, dynamic>> definitions;

    switch (templateKey) {
      case 'design_sprint':
        definitions = [
          {'title': 'Understand the problem', 'offsetDays': 0, 'time': '10:00'},
          {'title': 'Map user journey', 'offsetDays': 1, 'time': '11:00'},
          {'title': 'Sketch solutions', 'offsetDays': 2, 'time': '11:00'},
          {'title': 'Prototype key flows', 'offsetDays': 3, 'time': '10:00'},
          {
            'title': 'User testing & insights',
            'offsetDays': 4,
            'time': '15:00',
          },
        ];
        break;
      case 'product_launch':
        definitions = [
          {
            'title': 'Define launch goals & KPIs',
            'offsetDays': 0,
            'time': '10:00',
          },
          {
            'title': 'Prepare landing page & assets',
            'offsetDays': 1,
            'time': '11:00',
          },
          {
            'title': 'Plan marketing channels',
            'offsetDays': 2,
            'time': '14:00',
          },
          {'title': 'Soft launch & QA', 'offsetDays': 3, 'time': '11:00'},
          {
            'title': 'Full launch & monitoring',
            'offsetDays': 4,
            'time': '09:00',
          },
        ];
        break;
      default:
        return;
    }

    final newTasks = <Task>[];

    for (final def in definitions) {
      final offsetDays = def['offsetDays'] as int;
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: offsetDays));
      final title = def['title'] as String;
      final time = def['time'] as String;

      final task = Task(
        id: '',
        title: title,
        date: date,
        time: time,
        isCompleted: false,
        projectId: _project.id,
        userId: userId,
      );

      try {
        final created = await _taskRepository.createTask(task);
        newTasks.add(created);
      } catch (_) {}
    }

    if (newTasks.isEmpty || !mounted) return;

    setState(() {
      final updatedTasks = [..._project.tasks, ...newTasks];
      final completedCount = updatedTasks.where((t) => t.isCompleted).length;
      final newProgress = updatedTasks.isEmpty
          ? 0.0
          : completedCount / updatedTasks.length;

      _project = _project.copyWith(tasks: updatedTasks, progress: newProgress);
      widget.onUpdate(_project);
      _updateFilteredTasks();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template tasks added to project'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadSubtasksForAllTasks() async {
    for (var task in _project.tasks) {
      await _loadSubtasksForTask(task.id);
    }
  }

  Future<void> _loadSubtasksForTask(String taskId) async {
    try {
      // Cancel existing subscription if any
      _subtaskSubscriptions[taskId]?.cancel();

      // Subscribe to real-time subtask updates
      _subtaskSubscriptions[taskId] = _subtaskRepository
          .watchSubtasks(taskId)
          .listen((subtasks) {
            setState(() {
              _taskSubtasks[taskId] = subtasks;
            });
          });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading subtasks for task $taskId: $e');
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      // Pick image from gallery
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Uploading image...'),
            ],
          ),
          duration: Duration(minutes: 1),
        ),
      );

      // Upload to Supabase Storage
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName =
          '${_project.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'project_images/$fileName';

      await Supabase.instance.client.storage
          .from('DevFlow')
          .uploadBinary(filePath, bytes);

      // Get public URL
      final imageUrl = Supabase.instance.client.storage
          .from('DevFlow')
          .getPublicUrl(filePath);

      print('DEBUG: Uploaded image URL: $imageUrl');

      // Update project with new image URL
      final updatedProject = _project.copyWith(imagePath: imageUrl);
      print('DEBUG: Updated project imagePath: ${updatedProject.imagePath}');

      await _projectRepository.updateProject(updatedProject);
      print('DEBUG: Project updated in database');

      setState(() {
        _project = updatedProject;
      });

      widget.onUpdate(updatedProject);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image uploaded successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _subtaskController.dispose();
    _taskSubscription.cancel();
    _projectSubscription.cancel();
    for (var subscription in _subtaskSubscriptions.values) {
      subscription.cancel();
    }
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
    final wasCompleted = task.completed;
    final now = DateTime.now();
    final isNowCompleted = !task.completed;
    final updatedTask = task.copyWith(
      isCompleted: isNowCompleted,
      completed: isNowCompleted,
      completedAt: isNowCompleted ? now : null,
      clearCompletedAt: !isNowCompleted,
    );
    _optimisticUpdateTask(updatedTask);

    try {
      await _taskRepository.updateTask(updatedTask);

      // If this is a recurring task and we just completed it, create the next occurrence
      if (!wasCompleted && isNowCompleted && updatedTask.isRecurring) {
        await _createNextRecurringTask(updatedTask);
      }

      // Send FCM notification when task is completed
      if (isNowCompleted) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await FCMService().sendNotification(
            userId: userId,
            title: '🎯 Task Completed in ${_project.title}',
            body: 'You completed: ${task.title}',
            data: {'type': 'task', 'taskId': task.id, 'projectId': _project.id},
          );
        }
      }
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

  // ...existing code...
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
          assignedUserId:
              null, // Set to null until real user management is implemented
        );

        // Optimistically update UI
        _optimisticUpdateTask(updatedTask);

        await _taskRepository.updateTask(updatedTask);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task updated successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Add new task
        final uuid = Uuid();
        final currentUser = Supabase.instance.client.auth.currentUser;

        final newTask = Task(
          id: uuid.v4(),
          title: _taskTitleController.text.trim(),
          date: _selectedDate,
          time:
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          isCompleted: false,
          assignedUserId:
              null, // Set to null until real user management is implemented
          projectId: _project.id,
          userId: currentUser?.id ?? '',
        );

        // Optimistically update UI before API call
        if (mounted) {
          setState(() {
            final updatedTasks = [..._project.tasks, newTask];
            final completedCount = updatedTasks
                .where((t) => t.isCompleted)
                .length;
            final newProgress = updatedTasks.isEmpty
                ? 0.0
                : completedCount / updatedTasks.length;

            _project = _project.copyWith(
              tasks: updatedTasks,
              progress: newProgress,
            );
            widget.onUpdate(_project);
            _updateFilteredTasks();
          });
        }

        await _taskRepository.createTask(newTask);

        // Set up real-time subscription for the new task's subtasks
        await _loadSubtasksForTask(newTask.id);

        // Send FCM notification
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await FCMService().sendNotification(
            userId: userId,
            title: '📝 New Task Added to ${_project.title}',
            body: 'Task: ${newTask.title}',
            data: {
              'type': 'task',
              'taskId': newTask.id,
              'projectId': _project.id,
            },
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task "${newTask.title}" created successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      _resetDialogState();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving task: $e');
      }

      // Reload data to revert optimistic update
      await _loadProjectData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // ...existing code...

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

  void _assignProjectUser(String? userId) async {
    final previousUserId = _selectedProjectUserId;
    final currentUser = Supabase.instance.client.auth.currentUser;

    setState(() {
      _selectedProjectUserId = userId;
      _project = _project.copyWith(assignedUserId: userId);
    });

    try {
      // Save to database
      await _projectRepository.updateProject(_project);
      widget.onUpdate(_project);

      // Create share entry and send notification if assigning to a different user
      print(
        '🔔 DEBUG: Assignment check - userId: $userId, previousUserId: $previousUserId, currentUserId: ${currentUser?.id}',
      );

      if (userId != null && userId != previousUserId) {
        print(
          '🔔 DEBUG: User ID changed, checking if different from current user...',
        );

        // Only create share and send notification if assigning to someone else (not yourself)
        if (userId != currentUser?.id) {
          print(
            '🔔 DEBUG: Assigning to different user - creating share entry...',
          );
          print('🔔 Project ID: ${_project.id}');
          print('🔔 Shared with: $userId');

          // Create share entry in shared_projects table
          try {
            await _sharedItemsRepository.shareProject(
              projectId: _project.id,
              sharedWithUserId: userId,
              permission: 'edit', // Assigned users get edit permission
            );
            print('🔔 DEBUG: Share entry created successfully!');
          } catch (shareError) {
            print('⚠️ DEBUG: Failed to create share entry: $shareError');
            print('⚠️ DEBUG: Share error details: ${shareError.toString()}');
            // Continue even if share creation fails
          }

          // Send notification
          print('🔔 DEBUG: Sending project assignment notification...');
          await NotificationService().sendNotification(
            userId: userId,
            title: 'New Project Assignment',
            body: 'You have been assigned to project: ${_project.title}',
            type: 'project_assignment',
            data: {'project_id': _project.id, 'project_title': _project.title},
          );

          print('🔔 DEBUG: Project assignment notification sent!');
        }
      }

      // Remove share entry if user was unassigned
      if (userId == null && previousUserId != null) {
        print('🔔 DEBUG: User unassigned, removing share entry...');
        // Note: We'd need to query for the share entry ID first to delete it
        // For now, we'll leave orphaned shares (they won't be accessible anyway)
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User assigned successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ DEBUG: Error in _assignProjectUser: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    final selectedTime = _parseTimeString(task.time);

    AddEditTaskDialog.show(
      context,
      task: task,
      initialDate: task.date,
      initialTime: selectedTime,
      onSubmit:
          (
            title,
            date,
            time,
            assignedUserId,
            locationName,
            latitude,
            longitude,
            isRecurring,
            recurrencePattern,
          ) async {
            final updatedTask = task.copyWith(
              title: title,
              date: date,
              time:
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              assignedUserId: assignedUserId,
              locationName: locationName,
              latitude: latitude,
              longitude: longitude,
              isRecurring: isRecurring,
              recurrencePattern: recurrencePattern,
            );

            // Optimistically update UI
            _optimisticUpdateTask(updatedTask);

            try {
              await _taskRepository.updateTask(updatedTask);

              // Send notification if task was assigned to someone
              if (assignedUserId != null && assignedUserId.isNotEmpty) {
                final currentUser = Supabase.instance.client.auth.currentUser;
                // Only send notification if assigning to someone else
                if (assignedUserId != currentUser?.id) {
                  try {
                    await NotificationService().sendNotification(
                      userId: assignedUserId,
                      type: 'task_assigned',
                      title: 'Task Assigned',
                      body: 'You have been assigned to "${title}"',
                      data: {
                        'task_id': task.id,
                        'project_id': _project.id,
                        'project_title': _project.title,
                      },
                    );
                  } catch (e) {
                    if (kDebugMode) {
                      print('Failed to send notification: $e');
                    }
                  }
                }
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task updated successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error updating task: $e');
              }

              // Reload data to revert optimistic update
              await _loadProjectData();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update task: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
    );
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
              color: Colors.black,
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
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: DarkThemeColors.primary100),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
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
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            ProjectDetailsAppBar(
              onAddDesignSprintTemplate: () =>
                  _addTemplateTasksToProject('design_sprint'),
              onAddProductLaunchTemplate: () =>
                  _addTemplateTasksToProject('product_launch'),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Image Header
                    ProjectImageHeader(
                      project: _project,
                      onEditImage: _pickAndUploadImage,
                    ),

                    // Project Info Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Created Date
                          AnimatedFadeSlide(
                            delay: 0.0,
                            child: Text(
                              '${_formatDate(_project.createdDate)} (created)',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: DarkThemeColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Title and Member Avatars Row
                          AnimatedFadeSlide(
                            delay: 0.1,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _project.title,
                                    style: AppTextStyles.headlineSmall.copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: DarkThemeColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ProjectMemberAvatars(
                                  projectId: _project.id,
                                  maxVisible: 4,
                                  size: 32,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Action Buttons Row
                          AnimatedFadeSlide(
                            delay: 0.2,
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final membersRepo =
                                          ProjectMembersRepository();
                                      final members = await membersRepo
                                          .getProjectMembers(_project.id);
                                      if (!mounted) return;
                                      await showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        isScrollControlled: true,
                                        builder: (ctx) => ManageMembersDialog(
                                          projectId: _project.id,
                                          currentMembers: members,
                                          onMembersChanged: () {
                                            setState(() {
                                              // Refresh UI to show updated members
                                            });
                                          },
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.group, size: 18),
                                    label: const Text('Members'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          DarkThemeColors.primary100,
                                      side: BorderSide(
                                        color: DarkThemeColors.primary100
                                            .withOpacity(0.5),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await showDialog(
                                        context: context,
                                        builder: (ctx) => ProjectAttachmentsDialog(
                                          projectId: _project.id,
                                          onAttachmentsChanged: () {
                                            // Optional: refresh any attachment-related UI
                                          },
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.attach_file,
                                      size: 18,
                                    ),
                                    label: const Text('Attachments'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          DarkThemeColors.primary100,
                                      side: BorderSide(
                                        color: DarkThemeColors.primary100
                                            .withOpacity(0.5),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          AnimatedFadeSlide(
                            delay: 0.3,
                            child: Text(
                              _project.description,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: DarkThemeColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Status and Deadline Row
                          AnimatedFadeSlide(
                            delay: 0.4,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: _getStatusColor(
                                              _project.status,
                                            ).withOpacity(0.5),
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusText(_project.status),
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            color:
                                                DarkThemeColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _project.deadline,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: DarkThemeColors
                                                      .textPrimary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Assigned User Section
                          AnimatedFadeSlide(
                            delay: 0.5,
                            child: Column(
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
                          ),
                          const SizedBox(height: 24),

                          // Progress Section
                          AnimatedFadeSlide(
                            delay: 0.6,
                            child: ProjectProgressSection(project: _project),
                          ),
                          const SizedBox(height: 24),

                          // Task Tabs
                          AnimatedFadeSlide(
                            delay: 0.7,
                            child: TaskTabsWidget(
                              tabs: const ['All Task', 'Ongoing', 'Completed'],
                              selectedTab: _selectedTab,
                              onTabSelected: (tab) {
                                setState(() {
                                  _selectedTab = tab;
                                  _updateFilteredTasks();
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // View Toggle (List/Board selector)
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildViewToggle(),
                          ),
                          const SizedBox(height: 16),

                          // Task List
                          AnimatedSwitchFadeSlide(
                            key: ValueKey(_isKanbanView),
                            child: _buildTaskList(),
                          ),
                          const SizedBox(height: 100),
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
          AddEditTaskDialog.show(
            context,
            initialDate: DateTime.now(),
            initialTime: TimeOfDay.now(),
            onSubmit:
                (
                  title,
                  date,
                  time,
                  assignedUserId,
                  locationName,
                  latitude,
                  longitude,
                  isRecurring,
                  recurrencePattern,
                ) async {
                  final uuid = Uuid();
                  final currentUser = Supabase.instance.client.auth.currentUser;

                  // Validate UUID format - only accept valid UUIDs or null
                  String? validAssignedUserId;
                  if (assignedUserId != null && assignedUserId.length > 30) {
                    // Valid UUIDs are ~36 characters, dummy IDs are short like '1', '2'
                    validAssignedUserId = assignedUserId;
                  }

                  final newTask = Task(
                    id: uuid.v4(),
                    title: title,
                    date: date,
                    time:
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    isCompleted: false,
                    assignedUserId: validAssignedUserId,
                    projectId: _project.id,
                    userId: currentUser?.id ?? '',
                    locationName: locationName,
                    latitude: latitude,
                    longitude: longitude,
                    isRecurring: isRecurring,
                    recurrencePattern: recurrencePattern,
                  );

                  // Optimistically update UI before API call
                  if (mounted) {
                    setState(() {
                      final updatedTasks = [..._project.tasks, newTask];
                      final completedCount = updatedTasks
                          .where((t) => t.isCompleted)
                          .length;
                      final newProgress = updatedTasks.isEmpty
                          ? 0.0
                          : completedCount / updatedTasks.length;

                      _project = _project.copyWith(
                        tasks: updatedTasks,
                        progress: newProgress,
                      );
                      widget.onUpdate(_project);
                      _updateFilteredTasks();
                    });
                  }

                  try {
                    await _taskRepository.createTask(newTask);

                    print('🔔 DEBUG: Task created, checking assignment...');
                    print('🔔 validAssignedUserId: $validAssignedUserId');
                    print('🔔 currentUser?.id: ${currentUser?.id}');

                    // Send notification if task was assigned to someone
                    if (validAssignedUserId != null) {
                      print('🔔 DEBUG: Task has assigned user!');
                      final currentUser =
                          Supabase.instance.client.auth.currentUser;
                      // Only send notification if assigning to someone else
                      if (validAssignedUserId != currentUser?.id) {
                        print('🔔 DEBUG: Calling NotificationService...');
                        try {
                          final result = await NotificationService()
                              .sendNotification(
                                userId: validAssignedUserId,
                                type: 'task_assigned',
                                title: 'New Task Assigned',
                                body: 'You have been assigned to "${title}"',
                                data: {
                                  'task_id': newTask.id,
                                  'project_id': _project.id,
                                  'project_title': _project.title,
                                },
                              );
                          print('🔔 DEBUG: Notification result: $result');
                        } catch (e) {
                          if (kDebugMode) {
                            print('❌ Failed to send notification: $e');
                          }
                        }
                      } else {
                        print('🔔 DEBUG: Not sending - assigning to self');
                      }
                    } else {
                      print(
                        '🔔 DEBUG: No assigned user, skipping notification',
                      );
                    }

                    // Set up real-time subscription for the new task's subtasks
                    await _loadSubtasksForTask(newTask.id);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Task "${newTask.title}" created successfully',
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('Error saving task: $e');
                    }

                    // Reload data to revert optimistic update
                    await _loadProjectData();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save task: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
          );
        },
        backgroundColor: DarkThemeColors.primary100,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildViewToggle() {
    return AnimatedFadeSlide(
      delay: 0.15,
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isKanbanView = !_isKanbanView;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DarkThemeColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isKanbanView ? Icons.view_column : Icons.view_agenda,
                size: 16,
                color: DarkThemeColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _isKanbanView ? 'Board' : 'List',
                style: AppTextStyles.bodySmall.copyWith(
                  color: DarkThemeColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    if (_isKanbanView) {
      // In Kanban view we always work with the full project task list so
      // dragging between Todo/Done is consistent regardless of filter tab.
      if (_project.tasks.isEmpty) {
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

      return KanbanBoardWidget(
        tasks: _project.tasks,
        projectCardColor: _project.cardColor,
        onToggleCompletion: (task) {
          _toggleTaskCompletion(task);
        },
      );
    }

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
      children: _filteredTasks.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;
        return AnimatedFadeSlide(
          delay: 0.1 * index,
          child: _buildTaskItem(task),
        );
      }).toList(),
    );
  }

  Widget _buildTaskItem(Task task) {
    String monthName;
    switch (task.date.month) {
      case 1:
        monthName = 'Jan';
        break;
      case 2:
        monthName = 'Feb';
        break;
      case 3:
        monthName = 'Mar';
        break;
      case 4:
        monthName = 'Apr';
        break;
      case 5:
        monthName = 'May';
        break;
      case 6:
        monthName = 'Jun';
        break;
      case 7:
        monthName = 'Jul';
        break;
      case 8:
        monthName = 'Aug';
        break;
      case 9:
        monthName = 'Sep';
        break;
      case 10:
        monthName = 'Oct';
        break;
      case 11:
        monthName = 'Nov';
        break;
      case 12:
        monthName = 'Dec';
        break;
      default:
        monthName = '';
    }

    final dateString = '$monthName ${task.date.day}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Dismissible(
            key: Key(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.withOpacity(0.3), Colors.red],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            onDismissed: (direction) {
              _deleteTask(task);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: task.isCompleted
                      ? _project.cardColor.withOpacity(0.3)
                      : DarkThemeColors.border,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      _expandedTaskId = _expandedTaskId == task.id
                          ? null
                          : task.id;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Checkbox
                            GestureDetector(
                              onTap: () => _toggleTaskCompletion(task),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: task.isCompleted
                                        ? _project.cardColor
                                        : DarkThemeColors.border,
                                    width: 2.5,
                                  ),
                                  color: task.isCompleted
                                      ? _project.cardColor
                                      : Colors.transparent,
                                ),
                                child: task.isCompleted
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Task title and details
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
                                      fontSize: 15,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      // Date badge
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _project.cardColor
                                                .withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.calendar_today_rounded,
                                                size: 12,
                                                color: _project.cardColor,
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  dateString,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                        color:
                                                            _project.cardColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Time badge
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: DarkThemeColors.background,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 12,
                                                color: DarkThemeColors
                                                    .textSecondary,
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  task.time,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                        color: DarkThemeColors
                                                            .textSecondary,
                                                        fontSize: 12,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Timer button (for incomplete tasks)
                            if (!task.isCompleted) ...[
                              GestureDetector(
                                onTap: () async {
                                  final isThisTaskActive =
                                      _timeTracker.activeEntry?.taskId ==
                                      task.id;
                                  if (isThisTaskActive) {
                                    await _timeTracker.stopTracking();
                                  } else {
                                    await _timeTracker.startTracking(
                                      taskId: task.id,
                                      projectId: _project.id,
                                    );
                                  }
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _timeTracker.activeEntry?.taskId ==
                                            task.id
                                        ? _project.cardColor.withOpacity(0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          _timeTracker.activeEntry?.taskId ==
                                              task.id
                                          ? _project.cardColor
                                          : DarkThemeColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _timeTracker.activeEntry?.taskId ==
                                                task.id
                                            ? Icons.stop_circle_outlined
                                            : Icons.play_circle_outline,
                                        size: 18,
                                        color:
                                            _timeTracker.activeEntry?.taskId ==
                                                task.id
                                            ? _project.cardColor
                                            : DarkThemeColors.textSecondary,
                                      ),
                                      if (_timeTracker.activeEntry?.taskId ==
                                              task.id &&
                                          _timerDuration.isNotEmpty) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          _timerDuration,
                                          style: TextStyle(
                                            color: _project.cardColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],

                            // Expand/Edit button
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _expandedTaskId = _expandedTaskId == task.id
                                      ? null
                                      : task.id;
                                });
                              },
                              icon: Icon(
                                _expandedTaskId == task.id
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: DarkThemeColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        // Expanded content (location, assigned user, actions)
                        if (_expandedTaskId == task.id) ...[
                          const SizedBox(height: 16),
                          Divider(color: DarkThemeColors.border, height: 1),
                          const SizedBox(height: 16),

                          // Actions row
                          Row(
                            children: [
                              // Assigned user
                              if (task.assignedUserId != null) ...[
                                UserAvatar(
                                  user: DummyUsers.getUserById(
                                    task.assignedUserId!,
                                  ),
                                  radius: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DummyUsers.getUserById(
                                        task.assignedUserId!,
                                      )?.name ??
                                      'Assigned',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: DarkThemeColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                              ] else
                                const Spacer(),

                              // Add subtask button
                              IconButton(
                                icon: Icon(
                                  _addingSubtaskFor == task.id
                                      ? Icons.close_rounded
                                      : Icons.add_rounded,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _addingSubtaskFor =
                                        _addingSubtaskFor == task.id
                                        ? null
                                        : task.id;
                                  });
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: DarkThemeColors.background,
                                  foregroundColor: _project.cardColor,
                                ),
                                tooltip: 'Add subtask',
                              ),
                              const SizedBox(width: 8),

                              // Edit button
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showEditTaskDialog(task),
                                style: IconButton.styleFrom(
                                  backgroundColor: DarkThemeColors.background,
                                  foregroundColor:
                                      DarkThemeColors.textSecondary,
                                ),
                                tooltip: 'Edit task',
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Subtask input field
          if (_addingSubtaskFor == task.id)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12, right: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DarkThemeColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DarkThemeColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: DarkThemeColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter subtask title...',
                          hintStyle: AppTextStyles.bodySmall.copyWith(
                            color: DarkThemeColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _addSubtask(task.id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, size: 20),
                      color: _project.cardColor,
                      onPressed: () => _addSubtask(task.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),

          // Display subtasks
          if (_taskSubtasks[task.id] != null &&
              _taskSubtasks[task.id]!.isNotEmpty)
            _buildSubtasks(task.id),

          // Display location map card if task has location and is expanded
          if (_expandedTaskId == task.id &&
              task.latitude != null &&
              task.longitude != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TaskLocationMapCard(
                locationName: task.locationName ?? 'Task Location',
                latitude: task.latitude!,
                longitude: task.longitude!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskLocationMapScreen(
                        locationName: task.locationName ?? 'Task Location',
                        latitude: task.latitude!,
                        longitude: task.longitude!,
                        taskTitle: task.title,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubtasks(String taskId) {
    final subtasks = _taskSubtasks[taskId] ?? [];

    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 8, right: 40),
      child: Column(
        children: subtasks.map((subtask) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleSubtask(subtask.id, !subtask.isCompleted),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: subtask.isCompleted
                            ? _project.cardColor
                            : DarkThemeColors.border,
                        width: 2,
                      ),
                      color: subtask.isCompleted
                          ? _project.cardColor
                          : Colors.transparent,
                    ),
                    child: subtask.isCompleted
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subtask.title,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: subtask.isCompleted
                          ? DarkThemeColors.textSecondary
                          : DarkThemeColors.textPrimary,
                      decoration: subtask.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: DarkThemeColors.textSecondary,
                  ),
                  onPressed: () => _deleteSubtask(subtask.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete subtask',
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _addSubtask(String parentTaskId) async {
    if (kDebugMode) {
      print('🔵🔵🔵 _addSubtask method called for task: $parentTaskId');
    }

    final title = _subtaskController.text.trim();

    if (kDebugMode) {
      print('🔵 Text from controller: "$title" (isEmpty: ${title.isEmpty})');
    }

    if (title.isEmpty) {
      if (kDebugMode) {
        print('❌ Title is empty, returning early');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🔵 Starting to add subtask: $title for task: $parentTaskId');
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final uuid = Uuid();
      final subtask = Subtask(
        id: uuid.v4(),
        parentTaskId: parentTaskId,
        title: title,
        isCompleted: false,
        createdDate: DateTime.now(),
        ownerId: userId,
      );

      if (kDebugMode) {
        print('🔵 Calling repository to create subtask...');
      }

      // Immediately add to local list for instant UI update
      if (mounted) {
        setState(() {
          if (_taskSubtasks[parentTaskId] == null) {
            _taskSubtasks[parentTaskId] = [];
          }
          _taskSubtasks[parentTaskId]!.add(subtask);
        });
      }

      await _subtaskRepository.createSubtask(subtask);

      if (kDebugMode) {
        print('🔵 Subtask created, clearing input and closing form');
      }

      _subtaskController.clear();

      if (mounted) {
        setState(() {
          _addingSubtaskFor = null;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subtask "$title" added successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding subtask: $e');
      }

      // Remove from local list if creation failed
      if (mounted) {
        setState(() {
          _taskSubtasks[parentTaskId]?.removeWhere((s) => s.title == title);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add subtask: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleSubtask(String subtaskId, bool isCompleted) async {
    try {
      // Immediately update local state for instant UI feedback
      if (mounted) {
        setState(() {
          for (var taskId in _taskSubtasks.keys) {
            final subtaskIndex = _taskSubtasks[taskId]?.indexWhere(
              (s) => s.id == subtaskId,
            );
            if (subtaskIndex != null && subtaskIndex != -1) {
              _taskSubtasks[taskId]![subtaskIndex] =
                  _taskSubtasks[taskId]![subtaskIndex].copyWith(
                    isCompleted: isCompleted,
                  );
              break;
            }
          }
        });
      }

      await _subtaskRepository.toggleSubtaskCompletion(subtaskId, isCompleted);
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling subtask: $e');
      }

      // Revert the local change if the API call failed
      if (mounted) {
        setState(() {
          for (var taskId in _taskSubtasks.keys) {
            final subtaskIndex = _taskSubtasks[taskId]?.indexWhere(
              (s) => s.id == subtaskId,
            );
            if (subtaskIndex != null && subtaskIndex != -1) {
              _taskSubtasks[taskId]![subtaskIndex] =
                  _taskSubtasks[taskId]![subtaskIndex].copyWith(
                    isCompleted: !isCompleted,
                  );
              break;
            }
          }
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update subtask: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSubtask(String subtaskId) async {
    // Store the subtask for potential restoration
    Subtask? deletedSubtask;
    String? parentTaskId;

    try {
      // Immediately remove from local state for instant UI feedback
      if (mounted) {
        setState(() {
          for (var taskId in _taskSubtasks.keys) {
            final subtaskIndex = _taskSubtasks[taskId]?.indexWhere(
              (s) => s.id == subtaskId,
            );
            if (subtaskIndex != null && subtaskIndex != -1) {
              deletedSubtask = _taskSubtasks[taskId]![subtaskIndex];
              parentTaskId = taskId;
              _taskSubtasks[taskId]!.removeAt(subtaskIndex);
              break;
            }
          }
        });
      }

      await _subtaskRepository.deleteSubtask(subtaskId);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting subtask: $e');
      }

      // Restore the subtask if deletion failed
      if (mounted && deletedSubtask != null && parentTaskId != null) {
        setState(() {
          _taskSubtasks[parentTaskId]?.add(deletedSubtask!);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete subtask: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
