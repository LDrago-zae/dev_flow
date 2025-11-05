import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/presentation/widgets/custom_search_bar.dart';
import 'package:dev_flow/presentation/widgets/filter_chip_button.dart';
import 'package:dev_flow/presentation/widgets/project_card.dart';
import 'package:dev_flow/presentation/widgets/task_item.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DarkThemeColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectBottomSheet(context),
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
                _buildHeader(isDark),
                const SizedBox(height: 24),

                // Search Bar
                const CustomSearchBar(hintText: 'Search your project'),
                const SizedBox(height: 24),

                // Your Project Section
                _buildSectionHeader('Your Project', 'See All', isDark),
                const SizedBox(height: 16),
                _buildProjectsList(),
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
                color: isDark
                    ? DarkThemeColors.textSecondary
                    : LightThemeColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready to conquer your day?',
              style: TextStyle(
                color: isDark
                    ? DarkThemeColors.textPrimary
                    : LightThemeColors.textPrimary,
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
            color: isDark
                ? DarkThemeColors.textPrimary
                : LightThemeColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          actionText,
          style: TextStyle(
            color: isDark
                ? DarkThemeColors.primary100
                : LightThemeColors.primary300,
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
              final result = await Navigator.push(
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

  void _showAddProjectBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final deadlineController = TextEditingController();
    final categoryController = TextEditingController();
    double progress = 0.0;
    Color selectedColor = const Color(0xFF0062FF);

    final List<Color> colorOptions = [
      const Color(0xFF0062FF),
      const Color(0xFF40C4AA),
      const Color(0xFFFFBE4C),
      const Color(0xFFDF1C41),
      const Color(0xFF3381FF),
      const Color(0xFF66A1FF),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: BoxDecoration(
            color: DarkThemeColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: DarkThemeColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                Text(
                  'Add New Project',
                  style: TextStyle(
                    color: DarkThemeColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Project Title
                _buildLabel('Project Title'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: titleController,
                  hint: 'Enter project title',
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // Category
                _buildLabel('Category'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: categoryController,
                  hint: 'e.g., UI/UX, Development, Marketing',
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // Description
                _buildLabel('Description'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: descriptionController,
                  hint: 'Enter project description',
                  isDark: isDark,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Deadline
                _buildLabel('Deadline'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: deadlineController,
                  hint: 'Select deadline',
                  isDark: isDark,
                  readOnly: true,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 2),
                      ),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: DarkThemeColors.primary100,
                              onPrimary: Colors.white,
                              surface: DarkThemeColors.surface,
                              onSurface: DarkThemeColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      deadlineController.text = _formatDate(picked);
                    }
                  },
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    color: DarkThemeColors.icon,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 20),

                // Progress
                _buildLabel('Progress: ${(progress * 100).toInt()}%'),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: DarkThemeColors.primary100,
                    inactiveTrackColor: DarkThemeColors.border,
                    thumbColor: DarkThemeColors.primary100,
                    overlayColor: DarkThemeColors.primary100.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: progress,
                    onChanged: (value) {
                      setModalState(() {
                        progress = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Color Selection
                _buildLabel('Card Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: colorOptions.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? DarkThemeColors.primary100
                                : DarkThemeColors.border,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty &&
                          descriptionController.text.isNotEmpty &&
                          deadlineController.text.isNotEmpty &&
                          categoryController.text.isNotEmpty) {
                        setState(() {
                          _projects.add(
                            Project(
                              title: titleController.text,
                              description: descriptionController.text,
                              deadline: deadlineController.text,
                              createdDate: DateTime.now(),
                              progress: progress,
                              cardColor: selectedColor,
                              category: categoryController.text,
                              priority: ProjectPriority.medium,
                              status: ProjectStatus.ongoing,
                            ),
                          );
                        });
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please fill all fields'),
                            backgroundColor: DarkThemeColors.error,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DarkThemeColors.primary100,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Create Project',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: DarkThemeColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      style: TextStyle(color: DarkThemeColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: DarkThemeColors.textSecondary,
          fontSize: 14,
        ),
        filled: true,
        fillColor: DarkThemeColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DarkThemeColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DarkThemeColors.primary100, width: 1.5),
        ),
        suffixIcon: suffixIcon,
      ),
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
