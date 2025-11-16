import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/presentation/widgets/custom_search_bar.dart';
import 'package:dev_flow/presentation/widgets/project_card.dart';
import 'package:dev_flow/presentation/widgets/home/home_header.dart';
import 'package:dev_flow/presentation/widgets/home/section_header.dart';
import 'package:dev_flow/presentation/widgets/home/quick_todo_list.dart';
import 'package:dev_flow/presentation/widgets/project_details/kanban_board_widget.dart';
import 'package:dev_flow/presentation/widgets/home/fab_options_dialog.dart';
import 'package:dev_flow/presentation/dialogs/add_project_dialog.dart';
import 'package:dev_flow/presentation/dialogs/add_quick_todo_dialog.dart';
import 'package:dev_flow/presentation/views/project_details/project_details_screen.dart';
import 'package:dev_flow/presentation/views/activity/daily_task_detail_screen.dart';
import 'package:dev_flow/data/repositories/offline_project_repository.dart';
import 'package:dev_flow/data/repositories/offline_task_repository.dart';
import 'package:dev_flow/services/realtime_service.dart';
import 'package:dev_flow/services/fcm_service.dart';
import 'package:dev_flow/services/notification_service.dart';
import 'package:dev_flow/presentation/widgets/responsive_layout.dart';
import 'package:dev_flow/presentation/widgets/animated_fade_slide.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Data layer (offline-first repositories)
  final OfflineProjectRepository _projectRepository =
      OfflineProjectRepository();
  final OfflineTaskRepository _taskRepository = OfflineTaskRepository();
  final RealtimeService _realtimeService = RealtimeService();

  late StreamSubscription<Project> _projectSubscription;
  late StreamSubscription<Task> _taskSubscription;

  List<Project> _projects = [];
  List<Task> _quickTodos = [];
  List<Project> _filteredProjects = [];
  List<Task> _filteredQuickTodos = [];
  bool _isQuickTodosKanbanView = false;
  bool _isLoading = true;
  String? _error;
  String _userName = 'User';
  String _selectedFilter = 'All'; // For filtering quick todos
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _initializeData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _error = 'User not authenticated');
      return;
    }

    // Get user profile for name
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .single();
      _userName = profile['name'] ?? 'User';
    } catch (e) {
      // Use default name if profile not found
      _userName = 'User';
    }

    // Setup real-time subscriptions
    _realtimeService.subscribeToUserProjects(userId);
    _realtimeService.subscribeToUserTasks(userId);

    _projectSubscription = _realtimeService.projectUpdates.listen((project) {
      _updateProjectInList(project);
    });

    _taskSubscription = _realtimeService.taskUpdates.listen((task) {
      if (task.projectId == null) {
        _updateQuickTodoInList(task);
      } else {
        _updateTaskInProject(task);
      }
    });

    // Load initial data
    await _loadData();
  }

  Future<void> _loadData() async {
    // Don't clear existing data during refresh - keep showing old data with skeleton
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final projects = await _projectRepository.getProjects(userId);
      final quickTodos = await _taskRepository.getTasks(
        userId,
        projectId: null,
      );

      setState(() {
        _projects = projects;
        _quickTodos = quickTodos;
        _isLoading = false;
      });
      _filterData();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                'Failed to load data',
                style: TextStyle(
                  color: DarkThemeColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: DarkThemeColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.black,
            builder: (context) => FabOptionsDialog(
              onAddProject: () {
                // Capture the context before async operations
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                AddProjectDialog.show(
                  context,
                  onProjectCreated: (project, templateKey) async {
                    try {
                      await _projectRepository.createProject(project);
                      await _createTemplateTasksForProject(
                        project,
                        templateKey,
                      );
                      // Immediately add to list for instant UI update
                      if (mounted) {
                        setState(() {
                          _projects.insert(0, project);
                        });
                        // Show success message
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Project created successfully!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );

                        // Send notification if project assigned to someone
                        if (project.assignedUserId != null) {
                          final currentUser =
                              Supabase.instance.client.auth.currentUser;
                          if (project.assignedUserId != currentUser?.id) {
                            try {
                              await NotificationService().sendNotification(
                                userId: project.assignedUserId!,
                                type: 'project_assigned',
                                title: 'New Project Assigned',
                                body:
                                    'You have been assigned to "${project.title}"',
                                data: {
                                  'project_id': project.id,
                                  'project_title': project.title,
                                },
                              );
                            } catch (e) {
                              print('Failed to send project notification: $e');
                            }
                          }
                        }

                        // Send FCM notification
                        final userId =
                            Supabase.instance.client.auth.currentUser?.id;
                        if (userId != null) {
                          await FCMService().sendNotification(
                            userId: userId,
                            title: '🎉 New Project Created',
                            body: 'You created: ${project.title}',
                            data: {'type': 'project', 'projectId': project.id},
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to create project: $e'),
                          ),
                        );
                      }
                    }
                  },
                );
              },
              onAddQuickTodo: () {
                // Capture the context before async operations
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                AddQuickTodoDialog.show(
                  context,
                  onTodoCreated: (todo) async {
                    try {
                      await _taskRepository.createTask(todo);
                      // Immediately add to list for instant UI update
                      if (mounted) {
                        setState(() {
                          _quickTodos.insert(0, todo);
                        });
                        // Show success message
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Quick todo created successfully!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );

                        // Send notification if todo assigned to someone
                        if (todo.assignedUserId != null) {
                          final currentUser =
                              Supabase.instance.client.auth.currentUser;
                          // Only send if assigning to someone else
                          if (todo.assignedUserId != currentUser?.id) {
                            try {
                              await NotificationService().sendNotification(
                                userId: todo.assignedUserId!,
                                type: 'task_assigned',
                                title: 'New Task Assigned',
                                body:
                                    'You have been assigned to "${todo.title}"',
                                data: {'task_id': todo.id},
                              );
                            } catch (e) {
                              print('Failed to send todo notification: $e');
                            }
                          }
                        }

                        // Send FCM notification to self
                        final userId =
                            Supabase.instance.client.auth.currentUser?.id;
                        if (userId != null) {
                          await FCMService().sendNotification(
                            userId: userId,
                            title: '✅ New Quick Todo',
                            body: 'You created: ${todo.title}',
                            data: {'type': 'task', 'taskId': todo.id},
                          );
                        }
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
            ),
          );
        },
        backgroundColor: DarkThemeColors.primary100,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Skeletonizer(
              enabled: _isLoading,
              child: ResponsiveLayout(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  child: ResponsiveLayout(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section with notification icon
                        HomeHeader(userName: _userName, isDark: isDark),
                        const SizedBox(height: 24),

                        // Search Bar
                        CustomSearchBar(
                          hintText: 'Search projects and tasks',
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _filterData();
                          },
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: DarkThemeColors.textSecondary,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                    _filterData();
                                  },
                                )
                              : null,
                        ),
                        const SizedBox(height: 24),

                        // Your Project Section
                        SectionHeader(
                          title: 'Your Project',
                          actionText: 'See All',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildProjectsList(constraints),
                        const SizedBox(height: 24),

                        // Quick Todos Section
                        SectionHeader(
                          title: 'Quick Todos',
                          actionText: 'See All',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),

                        // Filter Chips and List/Board toggle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterChips(),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _buildQuickTodosViewToggle(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Quick Todos List
                        AnimatedSwitchFadeSlide(
                          key: ValueKey(_isQuickTodosKanbanView),
                          child: _isQuickTodosKanbanView
                              ? _buildQuickTodosKanban()
                              : _buildQuickTodosList(),
                        ),
                        const SizedBox(height: 32),

                        // Shared with Me Button
                        _buildSharedItemsButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _updateProjectInList(Project updatedProject) {
    setState(() {
      final index = _projects.indexWhere((p) => p.id == updatedProject.id);
      if (index != -1) {
        // Update existing project
        _projects[index] = updatedProject;
      } else {
        // Add new project at the beginning only if it doesn't exist
        // Check again to avoid duplicates from race conditions
        if (!_projects.any((p) => p.id == updatedProject.id)) {
          _projects.insert(0, updatedProject);
        }
      }
    });
    _filterData();
  }

  Future<void> _createTemplateTasksForProject(
    Project project,
    String? templateKey,
  ) async {
    if (templateKey == null) return;

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
        projectId: project.id,
        userId: userId,
      );

      try {
        await _taskRepository.createTask(task);
      } catch (_) {
        // Ignore template task creation failures for now
      }
    }
  }

  void _updateQuickTodoInList(Task updatedTask) {
    setState(() {
      final index = _quickTodos.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _quickTodos[index] = updatedTask;
      } else {
        // Add new todo at the beginning only if it doesn't exist
        if (!_quickTodos.any((t) => t.id == updatedTask.id)) {
          _quickTodos.insert(0, updatedTask);
        }
      }
    });
    _filterData();
  }

  void _updateTaskInProject(Task updatedTask) {
    setState(() {
      final projectIndex = _projects.indexWhere(
        (p) => p.id == updatedTask.projectId,
      );
      if (projectIndex != -1) {
        final taskIndex = _projects[projectIndex].tasks.indexWhere(
          (t) => t.id == updatedTask.id,
        );
        if (taskIndex != -1) {
          final updatedTasks = List<Task>.from(_projects[projectIndex].tasks);
          updatedTasks[taskIndex] = updatedTask;
          _projects[projectIndex] = _projects[projectIndex].copyWith(
            tasks: updatedTasks,
          );
        }
      }
    });
    _filterData();
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    // Optimistically update UI
    final wasCompleted = task.completed;
    final newCompleted = !task.completed;
    final updatedTask = task.copyWith(
      completed: newCompleted,
      isCompleted: newCompleted,
    );
    _updateQuickTodoInList(updatedTask);

    try {
      await _taskRepository.updateTask(updatedTask);

      // Send FCM notification when task is completed
      if (updatedTask.completed) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await FCMService().sendNotification(
            userId: userId,
            title: '🎯 Task Completed',
            body: 'You completed: ${task.title}',
            data: {'type': 'task', 'taskId': task.id},
          );
        }
      }

      // If this is a recurring task and we just completed it, create the next occurrence
      if (!wasCompleted && updatedTask.isRecurring) {
        await _createNextRecurringQuickTodo(updatedTask);
      }
    } catch (e) {
      // Revert on error
      _updateQuickTodoInList(task);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update task: $e')));
      }
    }
  }

  Future<void> _createNextRecurringQuickTodo(Task baseTask) async {
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
      final created = await _taskRepository.createTask(nextTask);
      _updateQuickTodoInList(created);
    } catch (_) {
      // If creating the next recurrence fails, ignore for now
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _projectSubscription.cancel();
    _taskSubscription.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  void _filterData() {
    setState(() {
      // Filter projects
      _filteredProjects = _projects.where((project) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            project.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            project.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            project.category.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesSearch;
      }).toList();

      // Filter quick todos
      _filteredQuickTodos = _quickTodos.where((todo) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            todo.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesFilter =
            _selectedFilter == 'All' ||
            (_selectedFilter == 'Completed' && todo.completed) ||
            (_selectedFilter == 'Pending' && !todo.completed);
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Widget _buildProjectsList(BoxConstraints constraints) {
    if (_filteredProjects.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: DarkThemeColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No projects yet' : 'No projects found',
              style: TextStyle(
                color: DarkThemeColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Always show actual projects if they exist - skeleton will overlay with their real colors
    final projectsToDisplay = _filteredProjects;

    return Column(
      children: projectsToDisplay.asMap().entries.map((entry) {
        final index = entry.key;
        final project = entry.value;
        return AnimatedFadeSlide(
          delay: index * 0.1,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ProjectCard(
              title: project.title,
              description: project.description,
              deadline: project.deadline,
              progress: project.progress,
              cardColor: project.cardColor,
              category: project.category,
              priority: project.priority,
              projectId: project.id,
              onTap: _isLoading
                  ? () {}
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailsScreen(
                            project: project,
                            onUpdate: (updated) {
                              setState(() {
                                _projects[index] = updated;
                              });
                              _filterData();
                            },
                          ),
                        ),
                      );
                      // Refresh data after returning from project details
                      await _loadData();
                    },
              onMorePressed: _isLoading
                  ? null
                  : () => _showProjectActionsSheet(project, index),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showProjectActionsSheet(Project project, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white),
                  title: const Text(
                    'Edit project',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    if (_isLoading) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectDetailsScreen(
                          project: project,
                          onUpdate: (updated) {
                            setState(() {
                              _projects[index] = updated;
                            });
                            _filterData();
                          },
                        ),
                      ),
                    );
                    // Refresh data after returning from project details
                    await _loadData();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Delete project',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _deleteProject(project, index);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteProject(Project project, int index) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      _projects.removeWhere((p) => p.id == project.id);
    });
    _filterData();

    try {
      await _projectRepository.deleteProject(project.id);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Project deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        await _loadData();
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to delete project: $e')),
        );
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

  Widget _buildFilterChips() {
    final filters = ['All', 'Pending', 'Completed'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final index = entry.key;
          final filter = entry.value;
          final isSelected = _selectedFilter == filter;
          return AnimatedFadeSlide(
            delay: index * 0.05,
            duration: const Duration(milliseconds: 400),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: FilterChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : DarkThemeColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    _filterData();
                  },
                  backgroundColor: Colors.black,
                  selectedColor: Colors.black,
                  checkmarkColor: DarkThemeColors.primary100,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickTodosViewToggle() {
    return AnimatedFadeSlide(
      delay: 0.2,
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isQuickTodosKanbanView = !_isQuickTodosKanbanView;
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
                _isQuickTodosKanbanView ? Icons.view_column : Icons.view_agenda,
                size: 16,
                color: DarkThemeColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _isQuickTodosKanbanView ? 'Board' : 'List',
                style: const TextStyle(
                  color: DarkThemeColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTodosKanban() {
    if (_filteredQuickTodos.isEmpty && !_isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DarkThemeColors.border, width: 1),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.task_alt,
              size: 48,
              color: DarkThemeColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? (_quickTodos.isEmpty
                        ? '✨ Start conquering your day!'
                        : 'No ${_selectedFilter.toLowerCase()} todos')
                  : 'No todos found',
              style: const TextStyle(
                color: DarkThemeColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) const SizedBox(height: 8),
            if (_searchQuery.isEmpty)
              const Text(
                'Tap the + button to add your quick tasks',
                style: TextStyle(
                  color: DarkThemeColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      );
    }

    final todosToDisplay = _isLoading && _filteredQuickTodos.isEmpty
        ? List.generate(
            3,
            (index) => Task(
              id: 'skeleton_$index',
              title: 'Loading Todo Title',
              date: DateTime.now(),
              time: '09:00',
              userId: '',
            ),
          )
        : _filteredQuickTodos;

    return KanbanBoardWidget(
      tasks: todosToDisplay,
      projectCardColor: DarkThemeColors.primary100,
      onToggleCompletion: _toggleTaskCompletion,
    );
  }

  Widget _buildQuickTodosList() {
    if (_filteredQuickTodos.isEmpty && !_isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DarkThemeColors.border, width: 1),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.task_alt,
              size: 48,
              color: DarkThemeColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? (_quickTodos.isEmpty
                        ? '✨ Start conquering your day!'
                        : 'No ${_selectedFilter.toLowerCase()} todos')
                  : 'No todos found',
              style: const TextStyle(
                color: DarkThemeColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) const SizedBox(height: 8),
            if (_searchQuery.isEmpty)
              const Text(
                'Tap the + button to add your quick tasks',
                style: TextStyle(
                  color: DarkThemeColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      );
    }

    // Show skeleton items when loading
    final todosToDisplay = _isLoading && _filteredQuickTodos.isEmpty
        ? List.generate(
            3,
            (index) => Task(
              id: 'skeleton_$index',
              title: 'Loading Todo Title',
              date: DateTime.now(),
              time: '09:00',
              userId: '',
            ),
          )
        : _filteredQuickTodos;

    return QuickTodoList(
      todos: todosToDisplay,
      onTodoTap: (todo) async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DailyTaskDetailScreen(task: todo),
          ),
        );
        // Refresh data after returning from task detail
        await _loadData();
      },
      onToggleComplete: _toggleTaskCompletion,
      formatDate: _formatDate,
    );
  }

  Widget _buildSharedItemsButton() {
    return InkWell(
      onTap: () {
        context.push('/shared-items');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.2),
              Colors.blue.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: Colors.purple,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shared with Me',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View projects & tasks shared by others',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
