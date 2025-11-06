import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/data/models/project_model.dart';

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
                        final project = Project(
                          title: titleController.text,
                          description: descriptionController.text,
                          deadline: deadlineController.text,
                          createdDate: DateTime.now(),
                          progress: progress,
                          cardColor: selectedColor,
                          category: categoryController.text,
                          priority: ProjectPriority.medium,
                          status: ProjectStatus.ongoing,
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
}
