import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/models/task_model.dart';

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

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _updateFilteredTasks();
  }

  void _updateFilteredTasks() {
    setState(() {
      switch (_selectedTab) {
        case 'Ongoing':
          _filteredTasks = _project.tasks.where((task) => !task.isCompleted).toList();
          break;
        case 'Completed':
          _filteredTasks = _project.tasks.where((task) => task.isCompleted).toList();
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

  void _toggleTaskCompletion(Task task) {
    setState(() {
      final updatedTasks = _project.tasks.map((t) {
        if (t.id == task.id) {
          return t.copyWith(isCompleted: !t.isCompleted);
        }
        return t;
      }).toList();

      final completedCount = updatedTasks.where((t) => t.isCompleted).length;
      final newProgress = updatedTasks.isEmpty ? 0.0 : completedCount / updatedTasks.length;

      _project = _project.copyWith(
        tasks: updatedTasks,
        progress: newProgress,
      );
      
      widget.onUpdate(_project);
      _updateFilteredTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                                        color: _getStatusColor(_project.status).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _getStatusColor(_project.status).withOpacity(0.5),
                                        ),
                                      ),
                                      child: Text(
                                        _getStatusText(_project.status),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: _getStatusColor(_project.status),
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
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: DarkThemeColors.textPrimary,
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
          decoration: BoxDecoration(
            color: DarkThemeColors.surface,
          ),
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
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 16,
            ),
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
                    final completedWidth = constraints.maxWidth * _project.progress;
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
                          child: Container(
                            color: DarkThemeColors.border,
                          ),
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      case 1: monthName = 'January'; break;
      case 2: monthName = 'February'; break;
      case 3: monthName = 'March'; break;
      case 4: monthName = 'April'; break;
      case 5: monthName = 'May'; break;
      case 6: monthName = 'June'; break;
      case 7: monthName = 'July'; break;
      case 8: monthName = 'August'; break;
      case 9: monthName = 'September'; break;
      case 10: monthName = 'October'; break;
      case 11: monthName = 'November'; break;
      case 12: monthName = 'December'; break;
      default: monthName = '';
    }
    
    final dateString = '${monthName} ${task.date.day}, ${task.date.year}';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
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
        ],
      ),
    );
  }
}
