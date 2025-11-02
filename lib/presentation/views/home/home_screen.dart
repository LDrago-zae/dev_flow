import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/filter_chip_button.dart';
import '../../widgets/project_card.dart';
import '../../widgets/task_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedBottomNavIndex = 0;
  String _selectedFilter = 'All Task';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DarkThemeColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(isDark),
                const SizedBox(height: 24),

                // Search Bar
                const CustomSearchBar(
                  hintText: 'Search your project',
                ),
                const SizedBox(height: 24),

                // Your Project Section
                _buildSectionHeader('Your Project', 'See All', isDark),
                const SizedBox(height: 16),
                ProjectCard(
                  title: 'E-commerce Platform Redesign - NovaShop',
                  description: 'Enhancing the user interface design of NovaShop, an e-commerce platform, for a more...',
                  deadline: 'January 30, 2025',
                  progress: 0.65,
                  cardColor: const Color(0xFF0062FF),
                  onTap: () {
                    // Navigate to project details
                  },
                ),
                const SizedBox(height: 24),

                // To Do List Section
                _buildSectionHeader('To Do List', 'See All', isDark),
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

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, Jenny',
              style: TextStyle(
                color: isDark ? DarkThemeColors.textSecondary : LightThemeColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready to conquer your day?',
              style: TextStyle(
                color: isDark ? DarkThemeColors.textPrimary : LightThemeColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? DarkThemeColors.surface : LightThemeColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? DarkThemeColors.border : LightThemeColors.border,
            ),
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: isDark ? DarkThemeColors.icon : LightThemeColors.icon,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String actionText, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? DarkThemeColors.textPrimary : LightThemeColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          actionText,
          style: TextStyle(
            color: isDark ? DarkThemeColors.primary100 : LightThemeColors.primary300,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
          onTap: () {
            // Navigate to task details
          },
        ),
        TaskItem(
          title: 'Marketing Campaign Launch',
          subtitle: 'Campaign Launch',
          date: 'January 10, 2025',
          time: '02:30 PM',
          onTap: () {
            // Navigate to task details
          },
        ),
        TaskItem(
          title: 'Client Meeting Preparation',
          subtitle: 'Client Meeting',
          date: 'January 8, 2025',
          time: '11:00 AM',
          onTap: () {
            // Navigate to task details
          },
        ),
        TaskItem(
          title: 'Budget Proposal Submission',
          subtitle: 'Budget Proposal',
          date: 'January 7, 2025',
          time: '3:00 PM',
          onTap: () {
            // Navigate to task details
          },
        ),
        TaskItem(
          title: 'Content Creation for Social Media',
          subtitle: 'Marketing Campaign',
          date: 'January 12, 2025',
          time: '9:30 AM',
          onTap: () {
            // Navigate to task details
          },
        ),
        TaskItem(
          title: 'Code Review and Debugging',
          subtitle: 'Software Development',
          date: 'January 14, 2025',
          time: '8:00 AM',
          onTap: () {
            // Navigate to task details
          },
        ),
      ],
    );
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
          top: BorderSide(
            color: DarkThemeColors.surface,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 3),
          child: GNav(curve: Curves.easeInOut,
            selectedIndex: _selectedBottomNavIndex,
            onTabChange: (index) {
              setState(() {
                _selectedBottomNavIndex = index;
              });
            },
            gap: 8,
            activeColor: isDark ? DarkThemeColors.primary100 : LightThemeColors.primary300,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: isDark
                ? DarkThemeColors.primary100.withOpacity(0.1)
                : LightThemeColors.primary300.withOpacity(0.1),
            color: isDark ? DarkThemeColors.textSecondary : LightThemeColors.textSecondary,
            tabs: const [
              GButton(
                icon: Icons.home_outlined,
                text: 'Home',
              ),
              GButton(
                icon: Icons.show_chart_outlined,
                text: 'Activity',
              ),
              GButton(
                icon: Icons.calendar_today_outlined,
                text: 'Timeline',
              ),
              GButton(
                icon: Icons.person_outline,
                text: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

