import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/data/models/project_model.dart';

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
  late Project _editedProject;
  bool _isEditMode = false;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _deadlineController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _editedProject = widget.project;
    _titleController = TextEditingController(text: widget.project.title);
    _descriptionController = TextEditingController(
      text: widget.project.description,
    );
    _deadlineController = TextEditingController(text: widget.project.deadline);
    _categoryController = TextEditingController(text: widget.project.category);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _deadlineController.dispose();
    _categoryController.dispose();
    super.dispose();
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

  DateTime? _parseDate(String dateString) {
    try {
      const months = {
        'January': 1,
        'February': 2,
        'March': 3,
        'April': 4,
        'May': 5,
        'June': 6,
        'July': 7,
        'August': 8,
        'September': 9,
        'October': 10,
        'November': 11,
        'December': 12,
      };

      final parts = dateString.split(' ');
      if (parts.length == 3) {
        final month = months[parts[0]];
        final day = int.tryParse(parts[1].replaceAll(',', ''));
        final year = int.tryParse(parts[2]);
        if (month != null && day != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditMode) {
        // Save changes
        _editedProject = _editedProject.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          deadline: _deadlineController.text,
          category: _categoryController.text,
        );
        widget.onUpdate(_editedProject);
      }
      _isEditMode = !_isEditMode;
    });
  }

  void _pickDate() async {
    final currentDate = _parseDate(_deadlineController.text) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
      setState(() {
        _deadlineController.text = _formatDate(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DarkThemeColors.background,
      appBar: AppBar(
        backgroundColor: DarkThemeColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DarkThemeColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditMode = false;
                  // Reset to original values
                  _titleController.text = widget.project.title;
                  _descriptionController.text = widget.project.description;
                  _deadlineController.text = widget.project.deadline;
                  _categoryController.text = widget.project.category;
                  _editedProject = widget.project;
                });
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: DarkThemeColors.textSecondary),
              ),
            ),
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.check : Icons.edit,
              color: DarkThemeColors.primary100,
            ),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _editedProject.cardColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _editedProject.cardColor.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  _editedProject.category,
                  style: TextStyle(
                    color: _editedProject.cardColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              if (!_isEditMode)
                Text(
                  _editedProject.title,
                  style: TextStyle(
                    color: DarkThemeColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Project Title'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'Enter project title',
                      isDark: isDark,
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Progress Section with Circular Progress
              _buildProgressSection(),
              const SizedBox(height: 32),

              // Description Section
              _buildLabel('Description'),
              const SizedBox(height: 8),
              if (!_isEditMode)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DarkThemeColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DarkThemeColors.border),
                  ),
                  child: Text(
                    _editedProject.description,
                    style: TextStyle(
                      color: DarkThemeColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                )
              else
                _buildTextField(
                  controller: _descriptionController,
                  hint: 'Enter project description',
                  isDark: isDark,
                  maxLines: 5,
                ),
              const SizedBox(height: 24),

              // Deadline Section
              _buildLabel('Deadline'),
              const SizedBox(height: 8),
              if (!_isEditMode)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DarkThemeColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DarkThemeColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: DarkThemeColors.icon,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _editedProject.deadline,
                        style: TextStyle(
                          color: DarkThemeColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildTextField(
                  controller: _deadlineController,
                  hint: 'Select deadline',
                  isDark: isDark,
                  readOnly: true,
                  onTap: _pickDate,
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    color: DarkThemeColors.icon,
                    size: 20,
                  ),
                ),
              const SizedBox(height: 24),

              // Category Section
              _buildLabel('Category'),
              const SizedBox(height: 8),
              if (!_isEditMode)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DarkThemeColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DarkThemeColors.border),
                  ),
                  child: Text(
                    _editedProject.category,
                    style: TextStyle(
                      color: DarkThemeColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                _buildTextField(
                  controller: _categoryController,
                  hint: 'e.g., UI/UX, Development, Marketing',
                  isDark: isDark,
                ),
              const SizedBox(height: 24),

              // Color Selection (only in edit mode)
              if (_isEditMode) ...[
                _buildLabel('Card Color'),
                const SizedBox(height: 8),
                _buildColorPicker(),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final List<Color> colorOptions = [
      const Color(0xFF0062FF),
      const Color(0xFF40C4AA),
      const Color(0xFFFFBE4C),
      const Color(0xFFDF1C41),
      const Color(0xFF3381FF),
      const Color(0xFF66A1FF),
    ];

    return Wrap(
      spacing: 12,
      children: colorOptions.map((color) {
        final isSelected = _editedProject.cardColor.value == color.value;
        return GestureDetector(
          onTap: () {
            setState(() {
              _editedProject = _editedProject.copyWith(cardColor: color);
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
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DarkThemeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DarkThemeColors.border),
      ),
      child: Column(
        children: [
          if (!_isEditMode) ...[
            // Circular Progress Indicator
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _editedProject.progress,
                    strokeWidth: 10,
                    backgroundColor: DarkThemeColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _editedProject.cardColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(_editedProject.progress * 100).toInt()}%',
                        style: TextStyle(
                          color: DarkThemeColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Complete',
                        style: TextStyle(
                          color: DarkThemeColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Project Progress',
              style: TextStyle(
                color: DarkThemeColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            _buildLabel(
              'Progress: ${(_editedProject.progress * 100).toInt()}%',
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _editedProject.cardColor,
                inactiveTrackColor: DarkThemeColors.border,
                thumbColor: _editedProject.cardColor,
                overlayColor: _editedProject.cardColor.withOpacity(0.2),
              ),
              child: Slider(
                value: _editedProject.progress,
                onChanged: (value) {
                  setState(() {
                    _editedProject = _editedProject.copyWith(progress: value);
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
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
}
