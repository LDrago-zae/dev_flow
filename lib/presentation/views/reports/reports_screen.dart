import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:dev_flow/data/repositories/task_repository.dart';
import 'package:dev_flow/data/repositories/project_repository.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:intl/intl.dart';
import 'package:dev_flow/presentation/widgets/responsive_layout.dart';
import 'package:dev_flow/presentation/widgets/reports/period_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:dev_flow/presentation/views/activity/daily_task_list_screen.dart';
import 'package:dev_flow/services/time_tracker_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const double _detailCardMinHeight = 220;
  String _selectedPeriod = 'Weekly';
  final List<String> _periods = ['Weekly', 'Monthly', 'Yearly'];

  final TaskRepository _taskRepository = TaskRepository();
  final ProjectRepository _projectRepository = ProjectRepository();

  List<Task> _allTasks = [];
  List<Project> _projects = [];
  List<ActivityHeatmapCell> _heatmapData = [];
  List<List<ActivityHeatmapCell>> _weekChunks = [];
  ActivityHeatmapCell? _selectedHeatmapCell;
  bool _isLoading = true;
  String _motivationalMessage = '';
  String _userName = 'there';
  final _timeTrackerService = TimeTrackerService();

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

      final quickTodos = await _taskRepository.getTasks(userId);
      final projects = await _projectRepository.getProjects(userId);
      final projectTasks = projects
          .expand((project) => project.tasks)
          .where((task) => task.userId == userId)
          .toList(growable: false);
      final combinedTasks = [...projectTasks, ...quickTodos];
      final heatmapData = _createHeatmapData(combinedTasks);
      ActivityHeatmapCell? initialSelection;
      for (final cell in heatmapData.reversed) {
        if (cell.intensity > 0) {
          initialSelection = cell;
          break;
        }
      }
      initialSelection ??= heatmapData.isNotEmpty ? heatmapData.last : null;

      final motivationalMsg = await _getMotivationalMessage();

      // Get user name from profile or auth metadata
      String userName = 'there';
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Try profile table first
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('name')
              .eq('id', userId)
              .maybeSingle();

          if (profile != null &&
              profile['name'] != null &&
              profile['name'].toString().isNotEmpty) {
            userName = (profile['name'] as String).split(' ').first;
          } else if (user.userMetadata?['full_name'] != null) {
            // Fallback to auth metadata (Google sign-in)
            userName = (user.userMetadata!['full_name'] as String)
                .split(' ')
                .first;
          } else if (user.email != null) {
            // Fallback to email username
            userName = user.email!.split('@').first;
          }
        }
      } catch (e) {
        print('Error loading user name: $e');
      }

      setState(() {
        _allTasks = combinedTasks;
        _projects = projects;
        _heatmapData = heatmapData;
        _selectedHeatmapCell = initialSelection;
        _motivationalMessage = motivationalMsg;
        _userName = userName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  // Calculate data based on actual tasks
  Map<String, dynamic> _getChartData() {
    final now = DateTime.now();
    final completedTasks = _allTasks.where((task) => task.isCompleted).toList();
    final incompletedTasks = _allTasks
        .where((task) => !task.isCompleted)
        .toList();

    if (_selectedPeriod == 'Weekly') {
      // Get tasks from the last 7 days
      final weekData = <ChartData>[];
      final daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayIndex = date.weekday % 7;

        final completedCount = completedTasks
            .where((task) {
              return task.date.year == date.year &&
                  task.date.month == date.month &&
                  task.date.day == date.day;
            })
            .length
            .toDouble();

        final incompletedCount = incompletedTasks
            .where((task) {
              return task.date.year == date.year &&
                  task.date.month == date.month &&
                  task.date.day == date.day;
            })
            .length
            .toDouble();

        weekData.add(
          ChartData(daysOfWeek[dayIndex], completedCount, incompletedCount),
        );
      }

      final performance = _allTasks.isEmpty
          ? 0
          : ((completedTasks.length / _allTasks.length) * 100).round();

      return {
        'data': weekData,
        'performance': performance,
        'completed': completedTasks.length,
        'incompleted': incompletedTasks.length,
      };
    } else if (_selectedPeriod == 'Monthly') {
      // Get tasks from the last 4 weeks
      final monthData = <ChartData>[];

      for (int week = 3; week >= 0; week--) {
        final startDate = now.subtract(Duration(days: (week + 1) * 7));
        final endDate = now.subtract(Duration(days: week * 7));

        final completedCount = completedTasks
            .where((task) {
              return task.date.isAfter(startDate) &&
                  task.date.isBefore(endDate);
            })
            .length
            .toDouble();

        final incompletedCount = incompletedTasks
            .where((task) {
              return task.date.isAfter(startDate) &&
                  task.date.isBefore(endDate);
            })
            .length
            .toDouble();

        monthData.add(
          ChartData('W${4 - week}', completedCount, incompletedCount),
        );
      }

      final performance = _allTasks.isEmpty
          ? 0
          : ((completedTasks.length / _allTasks.length) * 100).round();

      return {
        'data': monthData,
        'performance': performance,
        'completed': completedTasks.length,
        'incompleted': incompletedTasks.length,
      };
    } else {
      // Get tasks from the last 6 months
      final yearData = <ChartData>[];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthIndex = monthDate.month - 1;

        final completedCount = completedTasks
            .where((task) {
              return task.date.year == monthDate.year &&
                  task.date.month == monthDate.month;
            })
            .length
            .toDouble();

        final incompletedCount = incompletedTasks
            .where((task) {
              return task.date.year == monthDate.year &&
                  task.date.month == monthDate.month;
            })
            .length
            .toDouble();

        yearData.add(
          ChartData(months[monthIndex], completedCount, incompletedCount),
        );
      }

      final performance = _allTasks.isEmpty
          ? 0
          : ((completedTasks.length / _allTasks.length) * 100).round();

      return {
        'data': yearData,
        'performance': performance,
        'completed': completedTasks.length,
        'incompleted': incompletedTasks.length,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _getChartData();
    final chartDataList = data['data'] as List<ChartData>;
    final performance = data['performance'] as int;
    final completed = data['completed'] as int;
    final incompleted = data['incompleted'] as int;
    final completedBreakdown = _getSourceBreakdown(isCompleted: true);
    final incompletedBreakdown = _getSourceBreakdown(isCompleted: false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Skeletonizer(
        enabled: _isLoading,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ResponsiveLayout(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  child: ResponsiveLayout(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello $_userName',
                                  style: TextStyle(
                                    color: DarkThemeColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _motivationalMessage.isEmpty
                                      ? 'This is your performance'
                                      : _motivationalMessage,
                                  style: TextStyle(
                                    color: DarkThemeColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$performance%',
                              style: TextStyle(
                                color: DarkThemeColors.primary100,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Activity Heatmap
                        if (_heatmapData.isNotEmpty)
                          _buildActivityHeatmapSection(),

                        // Statistics Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Statistics',
                              style: TextStyle(
                                color: DarkThemeColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            PeriodSelector(
                              selectedPeriod: _selectedPeriod,
                              periods: _periods,
                              onPeriodChanged: (value) {
                                setState(() => _selectedPeriod = value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Chart
                        Container(
                          height: 350,
                          decoration: BoxDecoration(
                            color: const Color(0xFF050505),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF111111),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          child: SfCartesianChart(
                            plotAreaBorderWidth: 0,
                            primaryXAxis: CategoryAxis(
                              majorGridLines: const MajorGridLines(
                                width: 1,
                                color: Color(0xFF2A2A2A),
                              ),
                              labelStyle: const TextStyle(
                                color: Color(0xFF6B6B6B),
                                fontSize: 11,
                              ),
                              axisLine: const AxisLine(width: 0),
                            ),
                            primaryYAxis: NumericAxis(
                              isVisible: true,
                              interval: 40,
                              majorGridLines: const MajorGridLines(
                                width: 1,
                                color: Color(0xFF2A2A2A),
                              ),
                              labelStyle: const TextStyle(
                                color: Color(0xFF6B6B6B),
                                fontSize: 10,
                              ),
                              axisLine: const AxisLine(width: 0),
                            ),
                            series: <CartesianSeries>[
                              ColumnSeries<ChartData, String>(
                                dataSource: chartDataList,
                                xValueMapper: (ChartData data, _) => data.x,
                                yValueMapper: (ChartData data, _) =>
                                    data.taskCompleted,
                                name: 'Task Completed',
                                color: DarkThemeColors.primary100,
                                width: 0.5,
                                spacing: 0.3,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(3),
                                  topRight: Radius.circular(3),
                                ),
                              ),
                              ColumnSeries<ChartData, String>(
                                dataSource: chartDataList,
                                xValueMapper: (ChartData data, _) => data.x,
                                yValueMapper: (ChartData data, _) =>
                                    data.taskTargets,
                                name: 'Task Targets',
                                color: Colors.white,
                                width: 0.5,
                                spacing: 0.3,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(3),
                                  topRight: Radius.circular(3),
                                ),
                              ),
                            ],
                            legend: Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                              overflowMode: LegendItemOverflowMode.wrap,
                              legendItemBuilder:
                                  (
                                    String name,
                                    dynamic series,
                                    dynamic point,
                                    int index,
                                  ) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 16,
                                        top: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: index == 0
                                                  ? DarkThemeColors.primary100
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              color: Color(0xFF9E9E9E),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Detail Section
                        Text(
                          'Detail',
                          style: TextStyle(
                            color: DarkThemeColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Detail Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailCard(
                                icon: Icons.check_circle_outline,
                                title: 'Tasks Completed',
                                value: completed.toString(),
                                subtitle: _buildSourceSubtitle(
                                  completedBreakdown,
                                ),
                                onTap: () => _openTaskList(isCompleted: true),
                                sourceCounts: completedBreakdown,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDetailCard(
                                icon: Icons.radio_button_unchecked,
                                title: 'Tasks Incompleted',
                                value: incompleted.toString(),
                                subtitle: _buildSourceSubtitle(
                                  incompletedBreakdown,
                                ),
                                onTap: () => _openTaskList(isCompleted: false),
                                sourceCounts: incompletedBreakdown,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openTaskList({required bool isCompleted}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DailyTaskListScreen(
          isCompleted: isCompleted,
          title: isCompleted ? 'Completed Tasks' : 'Incompleted Tasks',
          color: isCompleted ? DarkThemeColors.primary100 : Colors.redAccent,
          includeProjectTasks: true,
          showTaskSource: true,
          projectNames: {
            for (final project in _projects) project.id: project.title,
          },
        ),
      ),
    );

    if (changed == true) {
      await _loadData();
    }
  }

  Widget _buildActivityHeatmapSection() {
    final hasAnyActivity = _heatmapData.any(
      (cell) => cell.metrics.values.any((v) => v > 0),
    );
    final subtitle = hasAnyActivity && _selectedHeatmapCell != null
        ? _buildHeatmapLabel(_selectedHeatmapCell!)
        : 'No activity tracked yet. Complete or schedule tasks to fill the map.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF131313), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Heatmap',
                      style: TextStyle(
                        color: DarkThemeColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Past 6 weeks of focused time & task flow',
                      style: TextStyle(
                        color: DarkThemeColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _heatColor(1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const Text(
                        'Higher activity',
                        style: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _weekChunks.length,
              itemBuilder: (context, weekIndex) {
                final week = _weekChunks[weekIndex];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: SizedBox(
                    width: 24,
                    height: 118,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (dayIndex) {
                        final cell = dayIndex < week.length
                            ? week[dayIndex]
                            : null;
                        final hasData =
                            cell?.metrics.values.any((v) => v > 0.0) ?? false;
                        final displayIntensity = hasData
                            ? math
                                  .max(0.2, cell!.intensity.clamp(0, 1))
                                  .toDouble()
                            : 0.0;
                        final isSelected =
                            hasData && _selectedHeatmapCell?.date == cell!.date;

                        return GestureDetector(
                          onTap: hasData
                              ? () {
                                  setState(() => _selectedHeatmapCell = cell);
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: hasData
                                  ? _heatColor(displayIntensity)
                                  : const Color(0xFF0D0D0D),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? DarkThemeColors.primary100
                                    : const Color(0xFF141414),
                                width: isSelected ? 1.3 : 1,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    VoidCallback? onTap,
    Map<String, int>? sourceCounts,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: _detailCardMinHeight),
        decoration: BoxDecoration(
          color: const Color(0xFF050505),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF101010),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF6B6B6B), size: 22),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: DarkThemeColors.primary100,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 11),
            ),
            _buildSourceChips(sourceCounts),
          ],
        ),
      ),
    );
  }

  Map<String, int> _getSourceBreakdown({required bool isCompleted}) {
    final relevantTasks = _allTasks.where(
      (task) => task.isCompleted == isCompleted,
    );
    final projectCount = relevantTasks
        .where((task) => task.projectId != null)
        .length;
    final quickCount = relevantTasks.length - projectCount;
    return {'projects': projectCount, 'quick': quickCount};
  }

  String _buildSourceSubtitle(Map<String, int> breakdown) {
    final projectCount = breakdown['projects'] ?? 0;
    final quickCount = breakdown['quick'] ?? 0;
    final parts = <String>[];
    if (projectCount > 0) {
      parts.add('$projectCount from projects');
    }
    if (quickCount > 0) {
      parts.add('$quickCount quick todo${quickCount == 1 ? '' : 's'}');
    }
    return parts.isEmpty ? 'No tasks yet' : parts.join(' • ');
  }

  Widget _buildSourceChips(Map<String, int>? counts) {
    if (counts == null) return const SizedBox.shrink();
    final chips = <Widget>[];
    final projectCount = counts['projects'] ?? 0;
    final quickCount = counts['quick'] ?? 0;

    if (projectCount > 0) {
      chips.add(
        _buildSourceChip(
          'Projects',
          projectCount,
          DarkThemeColors.primary100.withOpacity(0.2),
          DarkThemeColors.primary100,
        ),
      );
    }
    if (quickCount > 0) {
      chips.add(
        _buildSourceChip(
          'Quick Todos',
          quickCount,
          Colors.pinkAccent.withOpacity(0.2),
          Colors.pinkAccent,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(spacing: 8, runSpacing: 6, children: chips),
    );
  }

  Widget _buildSourceChip(
    String label,
    int count,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.4), width: 1),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<ActivityHeatmapCell> _createHeatmapData(List<Task> tasks) {
    if (tasks.isEmpty) return [];

    DateTime now = DateTime.now();
    DateTime startDate = now;
    for (final task in tasks) {
      if (task.date.isBefore(startDate)) startDate = task.date;
      if (task.completedAt != null && task.completedAt!.isBefore(startDate)) {
        startDate = task.completedAt!;
      }
    }

    // Align start date to the beginning of the week for consistent columns
    final weekdayOffset = startDate.weekday % 7;
    startDate = startDate.subtract(Duration(days: weekdayOffset));

    final totalDays = now.difference(startDate).inDays + 1;
    final Map<String, _DailyActivityMetrics> metricsMap = {
      for (int i = 0; i < totalDays; i++)
        _dateKey(startDate.add(Duration(days: i))): _DailyActivityMetrics(
          startDate.add(Duration(days: i)),
        ),
    };

    for (final task in tasks) {
      final minutes = (task.estimatedMinutes ?? 30).toDouble();
      final isProjectTask = task.projectId != null;

      final plannedKey = _dateKey(task.date);
      final plannedMetrics = metricsMap[plannedKey];
      if (plannedMetrics != null) {
        plannedMetrics.tasksPlanned += 1;
        plannedMetrics.totalMinutes += minutes;
        if (isProjectTask) {
          plannedMetrics.projectMinutes += minutes;
        } else {
          plannedMetrics.quickMinutes += minutes;
        }
      }

      if (task.completed && task.completedAt != null) {
        final completedKey = _dateKey(task.completedAt!);
        final completedMetrics = metricsMap[completedKey];
        if (completedMetrics != null) {
          completedMetrics.tasksCompleted += 1;
          completedMetrics.totalMinutes += minutes;
          if (isProjectTask) {
            completedMetrics.projectMinutes += minutes;
          } else {
            completedMetrics.quickMinutes += minutes;
          }
        }
      }
    }

    final cells =
        metricsMap.values
            .map(
              (metrics) => ActivityHeatmapCell(
                date: metrics.date,
                intensity: metrics.intensity,
                metrics: metrics.toMap(),
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    _weekChunks = [];
    for (int i = 0; i < cells.length; i += 7) {
      _weekChunks.add(cells.sublist(i, math.min(i + 7, cells.length)));
    }

    return cells;
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Color _heatColor(double intensity) {
    final clamped = intensity.clamp(0.0, 1.0);
    if (clamped < 0.25) return const Color(0xFF0F172A);
    if (clamped < 0.45) return const Color(0xFF1E3A8A);
    if (clamped < 0.65) return const Color(0xFF2563EB);
    if (clamped < 0.85) return const Color(0xFF10B981);
    return const Color(0xFF22D3EE);
  }

  String _buildHeatmapLabel(ActivityHeatmapCell cell) {
    final formatter = DateFormat('EEE, MMM d');
    final metrics = cell.metrics;
    final tasksPlanned = metrics['tasksPlanned']?.round() ?? 0;
    final tasksCompleted = metrics['tasksCompleted']?.round() ?? 0;
    final totalMinutes = metrics['totalMinutes'] ?? 0;
    final projectMinutes = metrics['projectMinutes'] ?? 0;
    final quickMinutes = metrics['quickMinutes'] ?? 0;

    return '${formatter.format(cell.date)} · '
        '$tasksPlanned planned · '
        '$tasksCompleted completed · '
        '${_formatMinutes(totalMinutes)} total · '
        '${_formatMinutes(projectMinutes)} on projects · '
        '${_formatMinutes(quickMinutes)} on quick todos';
  }

  String _formatMinutes(double minutes) {
    if (minutes <= 0) return '0m';
    if (minutes < 60) {
      return '${minutes.round()}m';
    }
    final hours = minutes / 60;
    if (hours >= 1 && hours < 10) {
      return '${hours.toStringAsFixed(1)}h';
    }
    return '${hours.round()}h';
  }

  Future<String> _getMotivationalMessage() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Get today's completed tasks
      final todayCompleted = _allTasks.where((task) {
        return task.isCompleted &&
            task.completedAt != null &&
            task.completedAt!.isAfter(startOfDay);
      }).length;

      // Get today's planned tasks
      final todayPlanned = _allTasks.where((task) {
        return task.date.year == today.year &&
            task.date.month == today.month &&
            task.date.day == today.day;
      }).length;

      // Try to get time tracked today (may fail if table doesn't exist yet)
      int timeSeconds = 0;
      try {
        timeSeconds = await _timeTrackerService.getTodayTotalSeconds();
      } catch (e) {
        print('Time tracker not available yet: $e');
      }
      final timeHours = timeSeconds / 3600;

      // Calculate performance score
      final completionRate = todayPlanned > 0
          ? (todayCompleted / todayPlanned)
          : 0;
      final hasGoodTime = timeHours >= 2; // At least 2 hours tracked
      final hasCompletedTasks = todayCompleted >= 3; // At least 3 tasks done

      // Determine message based on task completion (works without time tracker)
      if (completionRate >= 0.7 && todayCompleted >= 3) {
        return "You're slaying today! 🔥";
      } else if (hasGoodTime && hasCompletedTasks) {
        return "You're slaying today! 🔥";
      } else if (todayCompleted > 0) {
        return "Keep pushing hard! 💪";
      } else if (timeSeconds > 0) {
        return "Keep pushing hard! 💪";
      } else if (todayPlanned > 0) {
        return "Ready to crush it today?";
      } else {
        return "This is your performance";
      }
    } catch (e) {
      print('Error getting motivational message: $e');
      return 'This is your performance';
    }
  }
}

class ChartData {
  ChartData(this.x, this.taskCompleted, this.taskTargets);
  final String x;
  final double taskCompleted;
  final double taskTargets;
}

class ActivityHeatmapCell {
  final DateTime date;
  final double intensity;
  final Map<String, double> metrics;

  ActivityHeatmapCell({
    required this.date,
    required this.intensity,
    required this.metrics,
  });
}

class _DailyActivityMetrics {
  final DateTime date;
  double tasksPlanned = 0;
  double tasksCompleted = 0;
  double totalMinutes = 0;
  double projectMinutes = 0;
  double quickMinutes = 0;

  _DailyActivityMetrics(this.date);

  double get intensity {
    final taskScore = (tasksCompleted * 0.6) + (tasksPlanned * 0.3);
    final timeScore = totalMinutes / 180; // normalize 3h
    return (taskScore * 0.1 + timeScore).clamp(0, 1);
  }

  Map<String, double> toMap() => {
    'tasksPlanned': tasksPlanned,
    'tasksCompleted': tasksCompleted,
    'totalMinutes': totalMinutes,
    'projectMinutes': projectMinutes,
    'quickMinutes': quickMinutes,
  };
}
