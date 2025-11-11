import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:dev_flow/data/repositories/task_repository.dart';
import 'package:dev_flow/data/repositories/project_repository.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/presentation/widgets/responsive_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'Weekly';
  final List<String> _periods = ['Weekly', 'Monthly', 'Yearly'];

  final TaskRepository _taskRepository = TaskRepository();
  final ProjectRepository _projectRepository = ProjectRepository();

  List<Task> _allTasks = [];
  int _totalProjects = 0;
  bool _isLoading = true;

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

      setState(() {
        _allTasks = tasks;
        _totalProjects = projects.length;
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
                                  'Hello Jenny',
                                  style: TextStyle(
                                    color: DarkThemeColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'This is your performance',
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

                        // Statistics Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Statistics',
                              style: TextStyle(
                                color: DarkThemeColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF2A2A2A),
                                  width: 1,
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedPeriod,
                                isDense: true,
                                underline: const SizedBox(),
                                dropdownColor: const Color(0xFF1E1E1E),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                items: _periods.map((String period) {
                                  return DropdownMenuItem<String>(
                                    value: period,
                                    child: Text(period),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedPeriod = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Chart
                        Container(
                          height: 350,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D0D),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1A1A1A),
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
                                subtitle:
                                    'From $_totalProjects project${_totalProjects != 1 ? 's' : ''}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDetailCard(
                                icon: Icons.radio_button_unchecked,
                                title: 'Tasks Incompleted',
                                value: incompleted.toString(),
                                subtitle:
                                    'From $_totalProjects project${_totalProjects != 1 ? 's' : ''}',
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

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
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
                  color: const Color(0xFF1A1A1A),
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
          RichText(
            text: TextSpan(
              text: 'From ',
              style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 11),
              children: [
                TextSpan(
                  text: subtitle.replaceAll('From ', ''),
                  style: TextStyle(
                    color: DarkThemeColors.primary100,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard2({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
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
                  color: const Color(0xFF1A1A1A),
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
          RichText(
            text: TextSpan(
              text: 'From ',
              style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 11),
              children: [
                TextSpan(
                  text: subtitle.replaceAll('From ', ''),
                  style: TextStyle(
                    color: DarkThemeColors.primary100,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.taskCompleted, this.taskTargets);
  final String x;
  final double taskCompleted;
  final double taskTargets;
}
