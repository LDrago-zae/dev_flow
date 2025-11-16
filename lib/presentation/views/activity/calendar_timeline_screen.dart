import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/repositories/offline_task_repository.dart';
import 'package:dev_flow/data/repositories/offline_project_repository.dart';
import 'package:dev_flow/presentation/views/activity/daily_task_detail_screen.dart';
import 'package:dev_flow/presentation/views/project_details/project_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarTimelineScreen extends StatefulWidget {
  const CalendarTimelineScreen({super.key});

  @override
  State<CalendarTimelineScreen> createState() => _CalendarTimelineScreenState();
}

class _CalendarTimelineScreenState extends State<CalendarTimelineScreen> {
  final OfflineTaskRepository _taskRepository = OfflineTaskRepository();
  final OfflineProjectRepository _projectRepository =
      OfflineProjectRepository();

  bool _isLoading = true;
  List<Task> _tasks = [];
  List<Project> _projects = [];
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'day'; // 'day' or 'week'
  String _taskFilter =
      'All'; // All, Quick todos, Project tasks, Pending, Completed

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final tasks = await _taskRepository.getTasks(userId);
      final projects = await _projectRepository.getProjects(userId);

      if (!mounted) return;

      setState(() {
        _tasks = tasks;
        _projects = projects;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _startOfWeek(DateTime date) {
    // Monday as start of week
    final weekday = date.weekday; // 1 = Monday
    return _startOfDay(date).subtract(Duration(days: weekday - 1));
  }

  List<Task> _tasksForDate(DateTime date) {
    final day = _startOfDay(date);
    return _tasks.where((task) {
      final t = _startOfDay(task.date);
      final isSameDay =
          t.year == day.year && t.month == day.month && t.day == day.day;
      if (!isSameDay) return false;

      switch (_taskFilter) {
        case 'Quick todos':
          return task.projectId == null;
        case 'Project tasks':
          return task.projectId != null;
        case 'Pending':
          return !task.completed;
        case 'Completed':
          return task.completed;
        default:
          return true;
      }
    }).toList()..sort((a, b) => a.time.compareTo(b.time));
  }

  String _formatFullDate(DateTime date) {
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
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final weekdayName = weekdays[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$weekdayName, $monthName ${date.day}, ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  DateTime? _parseProjectDeadline(Project project) {
    final raw = project.deadline;
    if (raw.isEmpty) return null;

    // Try ISO-8601 or yyyy-MM-dd first
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    // Try "Month d, yyyy" format (e.g., "January 7, 2025")
    try {
      final parts = raw.split(' ');
      if (parts.length >= 3) {
        final monthName = parts[0];
        final dayPart = parts[1].replaceAll(',', '');
        final yearPart = parts[2];

        const monthNames = [
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
        final monthIndex = monthNames.indexOf(monthName) + 1;
        if (monthIndex > 0) {
          final day = int.parse(dayPart);
          final year = int.parse(yearPart);
          return DateTime(year, monthIndex, day);
        }
      }
    } catch (_) {
      // Ignore and fall through
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Calendar & Timeline',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: DarkThemeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Day'),
                        selected: _viewMode == 'day',
                        onSelected: (_) {
                          setState(() => _viewMode = 'day');
                        },
                        selectedColor: DarkThemeColors.primary100,
                        labelStyle: TextStyle(
                          color: _viewMode == 'day'
                              ? Colors.white
                              : DarkThemeColors.textSecondary,
                        ),
                        backgroundColor: Colors.black,
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Week'),
                        selected: _viewMode == 'week',
                        onSelected: (_) {
                          setState(() => _viewMode = 'week');
                        },
                        selectedColor: DarkThemeColors.primary100,
                        labelStyle: TextStyle(
                          color: _viewMode == 'week'
                              ? Colors.white
                              : DarkThemeColors.textSecondary,
                        ),
                        backgroundColor: Colors.black,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.subtract(
                              Duration(days: _viewMode == 'day' ? 1 : 7),
                            );
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.add(
                              Duration(days: _viewMode == 'day' ? 1 : 7),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _viewMode == 'day'
                      ? _formatFullDate(_selectedDate)
                      : _buildWeekRangeLabel(_selectedDate),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: DarkThemeColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DarkThemeColors.primary100,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildTasksSection(),
                          const SizedBox(height: 24),
                          _buildProjectTimelineSection(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildWeekRangeLabel(DateTime anchor) {
    final start = _startOfWeek(anchor);
    final end = start.add(const Duration(days: 6));
    return '${_formatShortDate(start)} - ${_formatShortDate(end)}';
  }

  Future<void> _openTaskFromCalendar(Task task) async {
    if (task.projectId == null) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => DailyTaskDetailScreen(task: task),
        ),
      );

      if (result == true) {
        await _loadData();
      }
    } else {
      final matchingProjects = _projects
          .where((p) => p.id == task.projectId)
          .toList();
      if (matchingProjects.isEmpty) {
        return;
      }
      final project = matchingProjects.first;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDetailsScreen(
            project: project,
            onUpdate: (updated) {
              setState(() {
                final index = _projects.indexWhere((p) => p.id == updated.id);
                if (index != -1) {
                  _projects[index] = updated;
                }
              });
            },
          ),
        ),
      );

      await _loadData();
    }
  }

  Future<void> _openProjectFromTimeline(Project project) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailsScreen(
          project: project,
          onUpdate: (updated) {
            setState(() {
              final index = _projects.indexWhere((p) => p.id == updated.id);
              if (index != -1) {
                _projects[index] = updated;
              }
            });
          },
        ),
      ),
    );

    await _loadData();
  }

  Widget _buildTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tasks',
          style: AppTextStyles.bodyLarge.copyWith(
            color: DarkThemeColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                [
                  'All',
                  'Quick todos',
                  'Project tasks',
                  'Pending',
                  'Completed',
                ].map((filter) {
                  final isSelected = _taskFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : DarkThemeColors.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: DarkThemeColors.primary100,
                      backgroundColor: Colors.black,
                      onSelected: (_) {
                        setState(() {
                          _taskFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DarkThemeColors.border.withOpacity(0.7)),
          ),
          padding: const EdgeInsets.all(16),
          child: _viewMode == 'day'
              ? _buildDayTasksView(_selectedDate)
              : _buildWeekTasksView(_selectedDate),
        ),
      ],
    );
  }

  Widget _buildDayTasksView(DateTime date) {
    final tasks = _tasksForDate(date);
    if (tasks.isEmpty) {
      return Text(
        'No tasks scheduled for this day.',
        style: AppTextStyles.bodySmall.copyWith(
          color: DarkThemeColors.textSecondary,
        ),
      );
    }

    return Column(
      children: tasks.map((task) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _openTaskFromCalendar(task),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: task.projectId == null
                        ? DarkThemeColors.primary100
                        : Colors.tealAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: DarkThemeColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            task.time,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: DarkThemeColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            task.projectId == null
                                ? Icons.check_box_outline_blank
                                : Icons.folder,
                            size: 14,
                            color: DarkThemeColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              task.projectId == null
                                  ? 'Quick todo'
                                  : 'Project task',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: DarkThemeColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (task.isRecurring &&
                          task.recurrencePattern != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.repeat,
                              size: 12,
                              color: Colors.orangeAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Repeats ${task.recurrencePattern}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.orangeAccent,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekTasksView(DateTime anchor) {
    final start = _startOfWeek(anchor);
    final days = List.generate(7, (index) => start.add(Duration(days: index)));

    return Column(
      children: days.map((day) {
        final tasks = _tasksForDate(day);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _viewMode = 'day';
                    _selectedDate = day;
                  });
                },
                child: Text(
                  _formatFullDate(day),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: DarkThemeColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (tasks.isEmpty)
                Text(
                  'No tasks',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: DarkThemeColors.textSecondary,
                    fontSize: 11,
                  ),
                )
              else
                Column(
                  children: tasks.take(3).map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        onTap: () => _openTaskFromCalendar(task),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: DarkThemeColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              task.time,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: DarkThemeColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (tasks.length > 3)
                Text(
                  '+${tasks.length - 3} more',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: DarkThemeColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              const Divider(
                height: 16,
                thickness: 0.4,
                color: Color(0xFF2A2A2A),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProjectTimelineSection() {
    if (_projects.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Timeline',
            style: AppTextStyles.bodyLarge.copyWith(
              color: DarkThemeColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DarkThemeColors.border.withOpacity(0.7),
              ),
            ),
            child: Text(
              'No projects available yet.',
              style: AppTextStyles.bodySmall.copyWith(
                color: DarkThemeColors.textSecondary,
              ),
            ),
          ),
        ],
      );
    }

    final timelines = <_ProjectTimelineRow>[];
    for (final project in _projects) {
      final start = project.createdDate;
      final end =
          _parseProjectDeadline(project) ??
          project.createdDate.add(const Duration(days: 7));
      final duration = end.difference(start).inDays.abs();
      timelines.add(
        _ProjectTimelineRow(
          project: project,
          start: start,
          end: end,
          durationDays: duration == 0 ? 1 : duration,
        ),
      );
    }

    final maxDuration = timelines.map((t) => t.durationDays).fold<int>(1, (
      prev,
      d,
    ) {
      return d > prev ? d : prev;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Timeline',
          style: AppTextStyles.bodyLarge.copyWith(
            color: DarkThemeColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DarkThemeColors.border.withOpacity(0.7)),
          ),
          child: Column(
            children: timelines.map((row) {
              final fraction = row.durationDays / maxDuration;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _openProjectFromTimeline(row.project),
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              row.project.title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: DarkThemeColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatShortDate(row.start)} - ${_formatShortDate(row.end)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: DarkThemeColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final barWidth = constraints.maxWidth * fraction;
                          final progressFraction = row.project.progress.clamp(
                            0.0,
                            1.0,
                          );
                          return Stack(
                            children: [
                              Container(
                                width: barWidth,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: row.project.cardColor.withOpacity(
                                    0.25,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              Container(
                                width: barWidth * progressFraction,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: row.project.cardColor,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Progress ${(row.project.progress * 100).toInt()}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: DarkThemeColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ProjectTimelineRow {
  final Project project;
  final DateTime start;
  final DateTime end;
  final int durationDays;

  _ProjectTimelineRow({
    required this.project,
    required this.start,
    required this.end,
    required this.durationDays,
  });
}
