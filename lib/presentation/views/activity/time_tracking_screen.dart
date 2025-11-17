import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/services/time_tracker_service.dart';
import 'package:dev_flow/data/repositories/task_repository.dart';
import 'package:dev_flow/data/repositories/project_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:dev_flow/presentation/widgets/animated_fade_slide.dart';

class TimeTrackingScreen extends StatefulWidget {
  const TimeTrackingScreen({super.key});

  @override
  State<TimeTrackingScreen> createState() => _TimeTrackingScreenState();
}

class _TimeTrackingScreenState extends State<TimeTrackingScreen> {
  final _timeTracker = TimeTrackerService();
  final _taskRepository = TaskRepository();
  final _projectRepository = ProjectRepository();

  List<_TimeTrackingItem> _items = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _loadTimeTrackingData();
  }

  Future<void> _loadTimeTrackingData() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Get all tasks and projects
      final tasks = await _taskRepository.getTasks(userId);
      final projects = await _projectRepository.getProjects(userId);

      // Get time entries for each task
      final items = <_TimeTrackingItem>[];

      for (final task in tasks) {
        final entries = await _timeTracker.getTaskTimeEntries(task.id);
        if (entries.isNotEmpty) {
          final totalSeconds = entries.fold<int>(
            0,
            (sum, entry) => sum + entry.durationSeconds,
          );

          // Find project name if task belongs to a project
          String? projectName;
          Color? projectColor;
          if (task.projectId != null) {
            final project = projects.firstWhere(
              (p) => p.id == task.projectId,
              orElse: () => projects.first,
            );
            projectName = project.title;
            projectColor = project.cardColor;
          }

          items.add(
            _TimeTrackingItem(
              id: task.id,
              title: task.title,
              type: 'Task',
              totalSeconds: totalSeconds,
              projectName: projectName,
              projectColor: projectColor,
              lastTracked: entries.first.updatedAt,
              entriesCount: entries.length,
            ),
          );
        }
      }

      // Get time entries for each project
      for (final project in projects) {
        final entries = await _timeTracker.getProjectTimeEntries(project.id);
        if (entries.isNotEmpty) {
          final totalSeconds = entries.fold<int>(
            0,
            (sum, entry) => sum + entry.durationSeconds,
          );

          items.add(
            _TimeTrackingItem(
              id: project.id,
              title: project.title,
              type: 'Project',
              totalSeconds: totalSeconds,
              projectColor: project.cardColor,
              lastTracked: entries.first.updatedAt,
              entriesCount: entries.length,
            ),
          );
        }
      }

      // Sort by total time (descending)
      items.sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading time tracking data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<_TimeTrackingItem> get _filteredItems {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'Today':
        final startOfDay = DateTime(now.year, now.month, now.day);
        return _items
            .where((item) => item.lastTracked.isAfter(startOfDay))
            .toList();

      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        return _items
            .where((item) => item.lastTracked.isAfter(startOfWeekDay))
            .toList();

      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return _items
            .where((item) => item.lastTracked.isAfter(startOfMonth))
            .toList();

      default:
        return _items;
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatLastTracked(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;
    final totalSeconds = filteredItems.fold<int>(
      0,
      (sum, item) => sum + item.totalSeconds,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedFadeSlide(
          delay: 0.05,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time Tracking',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: DarkThemeColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${filteredItems.length} items tracked',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: DarkThemeColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _loadTimeTrackingData,
                          icon: Icon(
                            Icons.refresh_rounded,
                            color: DarkThemeColors.primary100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Total time card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: DarkThemeColors.primary100.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: DarkThemeColors.primary100.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.timer_outlined,
                                  color: DarkThemeColors.primary100,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Total Time',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: DarkThemeColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatDuration(totalSeconds),
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: DarkThemeColors.primary100,
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedFilter = filter);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? DarkThemeColors.primary100
                                      : Colors.black,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? DarkThemeColors.primary100
                                        : DarkThemeColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  filter,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : DarkThemeColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: DarkThemeColors.primary100,
                        ),
                      )
                    : filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_off_outlined,
                              size: 64,
                              color: DarkThemeColors.textSecondary.withOpacity(
                                0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No time tracked yet',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: DarkThemeColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start tracking time on your tasks',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: DarkThemeColors.textSecondary
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _buildTimeTrackingCard(item);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeTrackingCard(_TimeTrackingItem item) {
    final isProject = item.type == 'Project';
    final color = item.projectColor ?? DarkThemeColors.primary100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Could navigate to task/project details
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isProject ? Icons.folder_outlined : Icons.task_alt_outlined,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: DarkThemeColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.type,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Project name for tasks
                          if (!isProject && item.projectName != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                item.projectName!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: DarkThemeColors.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: DarkThemeColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _formatLastTracked(item.lastTracked),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: DarkThemeColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.repeat_rounded,
                            size: 12,
                            color: DarkThemeColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.entriesCount}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: DarkThemeColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDuration(item.totalSeconds),
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            size: 12,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(item.totalSeconds / 3600).toStringAsFixed(1)}h',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeTrackingItem {
  final String id;
  final String title;
  final String type;
  final int totalSeconds;
  final String? projectName;
  final Color? projectColor;
  final DateTime lastTracked;
  final int entriesCount;

  _TimeTrackingItem({
    required this.id,
    required this.title,
    required this.type,
    required this.totalSeconds,
    this.projectName,
    this.projectColor,
    required this.lastTracked,
    required this.entriesCount,
  });
}
