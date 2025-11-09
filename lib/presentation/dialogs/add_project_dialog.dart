import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProjectDialog {
  static void show(
    BuildContext context, {
    required Function(Project) onProjectCreated,
  }) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final deadlineController = TextEditingController();
    final categoryController = TextEditingController();
    double progress = 0.0;
    Color selectedColor = LightThemeColors.cardBlue;
    ProjectPriority selectedPriority = ProjectPriority.medium;

    final List<Color> colorOptions = [
      LightThemeColors.cardBlue,
      LightThemeColors.cardRed,
      LightThemeColors.cardGold,
      LightThemeColors.cardGreen,
      LightThemeColors.cardPurple,
      LightThemeColors.cardTeal,
      LightThemeColors.cardIndigo,
      LightThemeColors.cardPink,
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
                ),
                const SizedBox(height: 20),

                // Category
                _buildLabel('Category'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: categoryController,
                  hint: 'e.g., UI/UX, Development, Marketing',
                ),
                const SizedBox(height: 20),

                // Description
                _buildLabel('Description'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: descriptionController,
                  hint: 'Enter project description',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Deadline
                _buildLabel('Deadline'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: deadlineController,
                  hint: 'Select deadline',
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
                    showValueIndicator: ShowValueIndicator.always,
                    valueIndicatorColor: DarkThemeColors.primary100,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Slider(
                    value: progress,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10, // Creates 11 steps: 0%, 10%, 20%, ..., 100%
                    label: '${(progress * 100).toInt()}%',
                    onChanged: (value) {
                      setModalState(() {
                        progress = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Priority Selection
                _buildLabel('Priority'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildPriorityChip(
                        label: 'High',
                        priority: ProjectPriority.high,
                        selectedPriority: selectedPriority,
                        onTap: () {
                          setModalState(() {
                            selectedPriority = ProjectPriority.high;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPriorityChip(
                        label: 'Medium',
                        priority: ProjectPriority.medium,
                        selectedPriority: selectedPriority,
                        onTap: () {
                          setModalState(() {
                            selectedPriority = ProjectPriority.medium;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPriorityChip(
                        label: 'Low',
                        priority: ProjectPriority.low,
                        selectedPriority: selectedPriority,
                        onTap: () {
                          setModalState(() {
                            selectedPriority = ProjectPriority.low;
                          });
                        },
                      ),
                    ),
                  ],
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
                        final project = Project(
                          id: Uuid().v4(),
                          title: titleController.text,
                          description: descriptionController.text,
                          deadline: deadlineController.text,
                          createdDate: DateTime.now(),
                          progress: progress,
                          cardColor: selectedColor,
                          category: categoryController.text,
                          priority: selectedPriority,
                          status: ProjectStatus.ongoing,
                          userId:
                              Supabase.instance.client.auth.currentUser?.id ??
                              '',
                        );
                        onProjectCreated(project);
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

  static String _formatDate(DateTime date) {
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

  static Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: DarkThemeColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
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

  static Widget _buildPriorityChip({
    required String label,
    required ProjectPriority priority,
    required ProjectPriority selectedPriority,
    required VoidCallback onTap,
  }) {
    final isSelected = priority == selectedPriority;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? DarkThemeColors.primary100
              : DarkThemeColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? DarkThemeColors.primary100
                : DarkThemeColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : DarkThemeColors.textSecondary,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
