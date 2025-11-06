import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/presentation/widgets/custom_search_bar.dart';
import 'package:dev_flow/presentation/widgets/filter_chip_button.dart';
import 'package:dev_flow/presentation/widgets/project_card.dart';
import 'package:dev_flow/presentation/widgets/task_item.dart';
import 'package:dev_flow/presentation/widgets/home/home_header.dart';
import 'package:dev_flow/presentation/widgets/home/section_header.dart';
import 'package:dev_flow/presentation/widgets/home/quick_todo_list.dart';
import 'package:dev_flow/presentation/widgets/home/fab_options_dialog.dart';
import 'package:dev_flow/presentation/dialogs/add_project_dialog.dart';
import 'package:dev_flow/presentation/dialogs/add_quick_todo_dialog.dart';
import 'package:dev_flow/presentation/views/project_details/project_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedBottomNavIndex = 0;
  String _selectedFilter = 'All Task';
  final List<Project> _projects = [
    Project(
      title: 'E-commerce Platform Redesign - NovaShop',
      description:
          'Overhauling the user interface design of NovaShop, our e-commerce platform, for a modern and user-friendly experience.',
      deadline: 'January 30, 2024',
      createdDate: DateTime(2023, 11, 12),
      progress: 0.70,
      cardColor: const Color(0xFF0062FF),
      category: 'UI/UX',
      priority: ProjectPriority.high,
      status: ProjectStatus.ongoing,
      tasks: [
        Task(
          id: '1',
          title: 'Conduct User Research',
          date: DateTime(2023, 11, 24),
          time: '10:00 AM',
          isCompleted: true,
        ),
        Task(
          id: '2',
          title: 'Wireframe New Homepage',
          date: DateTime(2023, 11, 30),
          time: '11:45 AM',
          isCompleted: true,
        ),
        Task(
          id: '3',
          title: 'Redesign Product Pages',
          date: DateTime(2023, 12, 4),
          time: '3:00 PM',
          isCompleted: false,
        ),
        Task(
          id: '4',
          title: 'Update Navigation Menu',
          date: DateTime(2023, 12, 8),
          time: '2:30 PM',
          isCompleted: false,
        ),
      ],
    ),
  ];
  final List<Task> _quickTodos = [];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DarkThemeColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => FabOptionsDialog(
              onAddProject: () => AddProjectDialog.show(
                context,
                onProjectCreated: (project) {
                  setState(() {
                    _projects.add(project);
                  });
                },
              ),
              onAddQuickTodo: () => AddQuickTodoDialog.show(
                context,
                onTodoCreated: (todo) {
                  setState(() {
                    _quickTodos.add(todo);
                  });
                },
              ),
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
                // Header Section
                HomeHeader(userName: 'Jenny', isDark: isDark),
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
                if (_quickTodos.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Quick Todos',
                    actionText: 'See All',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  QuickTodoList(
                    todos: _quickTodos,
                    onTodoTap: (todo) {
                      setState(() {
                        final index = _quickTodos.indexOf(todo);
                        _quickTodos[index] = todo.copyWith(
                          isCompleted: !todo.isCompleted,
                        );
                      });
                    },
                    formatDate: _formatDate,
                  ),
                  const SizedBox(height: 24),
                ],

                // To Do List Section
                SectionHeader(
                  title: 'To Do List',
                  actionText: 'See All',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Filter Chips
                _buildFilterChips(),
                const SizedBox(height: 16),

                // Task List
                _buildTaskList(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isDark),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All Task', 'Today', 'Ongoing', 'Completed'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChipButton(
              label: filter,
              isSelected: _selectedFilter == filter,
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskList() {
    return Column(
      children: [
        TaskItem(
          title: 'Complete Website Redesign',
          subtitle: 'Design Project',
          date: 'January 5, 2025',
          time: '10:00 AM',
          onTap: () {},
        ),
        TaskItem(
          title: 'Marketing Campaign Launch',
          subtitle: 'Campaign Launch',
          date: 'January 10, 2025',
          time: '02:30 PM',
          onTap: () {},
        ),
        TaskItem(
          title: 'Client Meeting Preparation',
          subtitle: 'Client Meeting',
          date: 'January 8, 2025',
          time: '11:00 AM',
          onTap: () {},
        ),
        TaskItem(
          title: 'Budget Proposal Submission',
          subtitle: 'Budget Proposal',
          date: 'January 7, 2025',
          time: '3:00 PM',
          onTap: () {},
        ),
        TaskItem(
          title: 'Content Creation for Social Media',
          subtitle: 'Marketing Campaign',
          date: 'January 12, 2025',
          time: '9:30 AM',
          onTap: () {},
        ),
        TaskItem(
          title: 'Code Review and Debugging',
          subtitle: 'Software Development',
          date: 'January 14, 2025',
          time: '8:00 AM',
          onTap: () {},
        ),
      ],
    );
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

  Widget _buildBottomNavigationBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: DarkThemeColors.background,
        border: Border(
          top: BorderSide(color: DarkThemeColors.surface, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 3),
          child: GNav(
            curve: Curves.easeInOut,
            selectedIndex: _selectedBottomNavIndex,
            onTabChange: (index) {
              setState(() {
                _selectedBottomNavIndex = index;
              });
            },
            gap: 8,
            activeColor: isDark
                ? DarkThemeColors.primary100
                : LightThemeColors.primary300,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: isDark
                ? DarkThemeColors.primary100.withOpacity(0.1)
                : LightThemeColors.primary300.withOpacity(0.1),
            color: isDark
                ? DarkThemeColors.textSecondary
                : LightThemeColors.textSecondary,
            tabs: const [
              GButton(icon: Icons.home_outlined, text: 'Home'),
              GButton(icon: Icons.show_chart_outlined, text: 'Activity'),
              GButton(icon: Icons.calendar_today_outlined, text: 'Timeline'),
              GButton(icon: Icons.person_outline, text: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
