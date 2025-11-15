import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/presentation/widgets/custom_search_bar.dart';
import 'package:dev_flow/presentation/widgets/project_card.dart';
import 'package:dev_flow/presentation/widgets/home/home_header.dart';
import 'package:dev_flow/presentation/widgets/home/section_header.dart';
import 'package:dev_flow/presentation/widgets/home/quick_todo_list.dart';
import 'package:dev_flow/presentation/widgets/home/fab_options_dialog.dart';
import 'package:dev_flow/presentation/dialogs/add_project_dialog.dart';
import 'package:dev_flow/presentation/dialogs/add_quick_todo_dialog.dart';
import 'package:dev_flow/presentation/views/project_details/project_details_screen.dart';
import 'package:dev_flow/presentation/views/activity/daily_task_detail_screen.dart';
import 'package:dev_flow/data/repositories/project_repository.dart';
import 'package:dev_flow/data/repositories/task_repository.dart';
import 'package:dev_flow/services/realtime_service.dart';
import 'package:dev_flow/services/fcm_service.dart';
import 'package:dev_flow/services/notification_service.dart';
import 'package:dev_flow/presentation/widgets/responsive_layout.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Supabase integration
  final ProjectRepository _projectRepository = ProjectRepository();
  final TaskRepository _taskRepository = TaskRepository();
  final RealtimeService _realtimeService = RealtimeService();

  late StreamSubscription<Project> _projectSubscription;
  late StreamSubscription<Task> _taskSubscription;

  List<Project> _projects = [];
  List<Task> _quickTodos = [];
  List<Project> _filteredProjects = [];
  List<Task> _filteredQuickTodos = [];

  bool _isLoading = true;
  String? _error;
  String _userName = 'User';
  String _selectedFilter = 'All'; // For filtering quick todos
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
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
                  onProjectCreated: (project) async {
                    try {
                      await _projectRepository.createProject(project);
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

                        // Filter Chips
                        _buildFilterChips(),
                        const SizedBox(height: 16),

                        // Quick Todos List
                        _buildQuickTodosList(),
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
    final updatedTask = task.copyWith(completed: !task.completed);
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

  @override
  void dispose() {
    _projectSubscription.cancel();
    _taskSubscription.cancel();
    _realtimeService.dispose();
    _searchController.dispose();
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

    // Show skeleton items when loading
    final projectsToDisplay = _isLoading && _filteredProjects.isEmpty
        ? List.generate(
            2,
            (index) => Project(
              id: 'skeleton_$index',
              title: 'Loading Project Title',
              description: 'Loading project description text here',
              deadline: DateTime.now()
                  .add(const Duration(days: 7))
                  .toIso8601String()
                  .split('T')[0],
              createdDate: DateTime.now(),
              progress: 0.5,
              tasks: [],
              userId: '',
              cardColor: DarkThemeColors.primary100,
              category: 'Development',
              priority: ProjectPriority.medium,
              status: ProjectStatus.ongoing,
            ),
          )
        : _filteredProjects;

    return Column(
      children: projectsToDisplay.asMap().entries.map((entry) {
        final index = entry.key;
        final project = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ProjectCard(
            title: project.title,
            description: project.description,
            deadline: project.deadline,
            progress: project.progress,
            cardColor: project.cardColor,
            category: project.category,
            priority: project.priority,
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
                          },
                        ),
                      ),
                    );
                  },
          ),
        );
      }).toList(),
    );
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
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
                _filterData();
              },
              backgroundColor: Colors.black,
              selectedColor: DarkThemeColors.surface,
              checkmarkColor: DarkThemeColors.primary100,
            ),
          );
        }).toList(),
      ),
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
      onTodoTap: (todo) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DailyTaskDetailScreen(task: todo),
          ),
        );
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
