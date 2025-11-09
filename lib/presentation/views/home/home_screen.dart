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
import 'package:dev_flow/data/repositories/project_repository.dart';
import 'package:dev_flow/data/repositories/task_repository.dart';
import 'package:dev_flow/services/realtime_service.dart';
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

  bool _isLoading = true;
  String? _error;
  String _userName = 'User';
  String _selectedFilter = 'All'; // For filtering quick todos

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with logout
                HomeHeader(
                  userName: _userName,
                  isDark: isDark,
                  onLogout: () async {
                    await Supabase.instance.client.auth.signOut();
                  },
                ),
                const SizedBox(height: 24),

                // Search Bar
                const CustomSearchBar(hintText: 'Search your project'),
                const SizedBox(height: 24),

                // Your Project Section
                SectionHeader(
                  title: 'Your Project',
                  actionText: 'See All',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildProjectsList(),
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
              ],
            ),
          ),
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
  }

  @override
  void dispose() {
    _projectSubscription.cancel();
    _taskSubscription.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  Widget _buildProjectsList() {
    if (_projects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: DarkThemeColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DarkThemeColors.border),
        ),
        child: Center(
          child: Text(
            'No projects yet. Tap the + button to add one!',
            style: TextStyle(
              color: DarkThemeColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: _projects.asMap().entries.map((entry) {
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
            onTap: () async {
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

  List<Task> _getFilteredQuickTodos() {
    if (_selectedFilter == 'All') {
      return _quickTodos;
    } else if (_selectedFilter == 'Pending') {
      return _quickTodos.where((todo) => !todo.isCompleted).toList();
    } else if (_selectedFilter == 'Completed') {
      return _quickTodos.where((todo) => todo.isCompleted).toList();
    }
    return _quickTodos;
  }

  Widget _buildQuickTodosList() {
    final filteredTodos = _getFilteredQuickTodos();

    if (filteredTodos.isEmpty) {
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
              _quickTodos.isEmpty
                  ? '✨ Start conquering your day!'
                  : 'No ${_selectedFilter.toLowerCase()} todos',
              style: const TextStyle(
                color: DarkThemeColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
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

    return QuickTodoList(
      todos: filteredTodos,
      onTodoTap: (todo) async {
        try {
          final updatedTodo = todo.copyWith(isCompleted: !todo.isCompleted);
          await _taskRepository.updateTask(updatedTodo);
          // Real-time subscription will update the UI
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to update todo: $e')));
        }
      },
      formatDate: _formatDate,
    );
  }
}
