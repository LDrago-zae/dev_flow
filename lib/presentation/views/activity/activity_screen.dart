import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/data/repositories/project_repository.dart';
import 'package:dev_flow/data/repositories/task_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'priority_projects_screen.dart';
import 'daily_task_list_screen.dart';
import 'package:dev_flow/presentation/dialogs/add_quick_todo_dialog.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  final ProjectRepository _projectRepository = ProjectRepository();
  final TaskRepository _taskRepository = TaskRepository();
  List<Project> _allProjects = [];
  List<Task> _quickTodos = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Refresh to show/hide FAB
    });
    _loadProjects();
    _loadQuickTodos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final projects = await _projectRepository.getProjects(userId);
        if (mounted) {
          setState(() {
            _allProjects = projects;
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

  Future<void> _loadQuickTodos() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final quickTodos = await _taskRepository.getTasks(
          userId,
          projectId: null,
        );

        if (mounted) {
          setState(() {
            _quickTodos = quickTodos;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  int _getProjectCountByPriority(ProjectPriority priority) {
    return _allProjects.where((p) => p.priority == priority).length;
  }

  int _getTaskCountByPriority(ProjectPriority priority) {
    return _allProjects
        .where((p) => p.priority == priority)
        .fold(0, (sum, project) => sum + project.tasks.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () {
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                AddQuickTodoDialog.show(
                  context,
                  onTodoCreated: (todo) async {
                    try {
                      await _taskRepository.createTask(todo);
                      // Reload todos to update the list
                      await _loadQuickTodos();
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
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Projects & Tasks',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: DarkThemeColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 24),
              // Tab Bar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: DarkThemeColors.primary100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Project'),
                    Tab(text: 'Daily Task'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildProjectsTab(), _buildDailyTasksTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DarkThemeColors.primary100),
      );
    }

    return ListView(
      children: [
        _buildPriorityCard(
          context,
          priority: ProjectPriority.high,
          title: 'High Priority Project',
          color: const Color(0xFF1E3A8A), // Dark blue
          projectCount: _getProjectCountByPriority(ProjectPriority.high),
          taskCount: _getTaskCountByPriority(ProjectPriority.high),
        ),
        const SizedBox(height: 16),
        _buildPriorityCard(
          context,
          priority: ProjectPriority.medium,
          title: 'Medium Priority Project',
          color: const Color(0xFF991B1B), // Dark red
          projectCount: _getProjectCountByPriority(ProjectPriority.medium),
          taskCount: _getTaskCountByPriority(ProjectPriority.medium),
        ),
        const SizedBox(height: 16),
        _buildPriorityCard(
          context,
          priority: ProjectPriority.low,
          title: 'Low Priority Project',
          color: const Color(0xFF78350F), // Dark orange/brown
          projectCount: _getProjectCountByPriority(ProjectPriority.low),
          taskCount: _getTaskCountByPriority(ProjectPriority.low),
        ),
      ],
    );
  }

  Widget _buildDailyTasksTab() {
    final completedCount = _quickTodos.where((t) => t.completed).length;
    final incompleteCount = _quickTodos.where((t) => !t.completed).length;

    return ListView(
      children: [
        _buildTaskCategoryCard(
          context,
          isCompleted: false,
          title: 'Incomplete Tasks',
          color: const Color(0xFF991B1B), // Dark red
          taskCount: incompleteCount,
        ),
        const SizedBox(height: 16),
        _buildTaskCategoryCard(
          context,
          isCompleted: true,
          title: 'Completed Tasks',
          color: const Color(0xFF065F46), // Dark green
          taskCount: completedCount,
        ),
      ],
    );
  }

  Widget _buildTaskCategoryCard(
    BuildContext context, {
    required bool isCompleted,
    required String title,
    required Color color,
    required int taskCount,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DailyTaskListScreen(
              isCompleted: isCompleted,
              title: title,
              color: color,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.pending_actions,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$taskCount',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$taskCount Task${taskCount != 1 ? 's' : ''}',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityCard(
    BuildContext context, {
    required ProjectPriority priority,
    required String title,
    required Color color,
    required int projectCount,
    required int taskCount,
  }) {
    final percentage = projectCount > 0
        ? (_allProjects
                      .where((p) => p.priority == priority)
                      .fold<double>(0, (sum, p) => sum + p.progress) /
                  projectCount *
                  100)
              .toInt()
        : 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PriorityProjectsScreen(
              priority: priority,
              title: title,
              color: color,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.folder,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$percentage%',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$projectCount Projects',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$taskCount Task',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
