import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/presentation/widgets/user_dropdown.dart';

class AddQuickTodoDialog {
  static void show(
    BuildContext context, {
    required Function(Task) onTodoCreated,
  }) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String? selectedUserId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            decoration: BoxDecoration(
              color: DarkThemeColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    'Add Quick Todo',
                    style: TextStyle(
                      color: DarkThemeColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Todo Title
                  _buildLabel('Todo Title'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: titleController,
                    hint: 'Enter todo title',
                  ),
                  const SizedBox(height: 16),

                  // Subtitle/Category
                  _buildLabel('Category'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: subtitleController,
                    hint: 'e.g., Personal, Work, Shopping',
                  ),
                  const SizedBox(height: 16),

                  // User Assignment
                  _buildLabel('Assign to'),
                  const SizedBox(height: 8),
                  UserDropdown(
                    selectedUserId: selectedUserId,
                    onUserSelected: (userId) {
                      setModalState(() {
                        selectedUserId = userId;
                      });
                    },
                    hintText: 'Assign to user',
                  ),
                  const SizedBox(height: 16),

                  // Date and Time Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Date'),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setModalState(() {
                                    selectedDate = date;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: DarkThemeColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      color: DarkThemeColors.textSecondary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                      style: TextStyle(
                                        color: DarkThemeColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Time'),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (time != null) {
                                  setModalState(() {
                                    selectedTime = time;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: DarkThemeColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 20,
                                      color: DarkThemeColors.textSecondary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: DarkThemeColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          final todo = Task(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleController.text,
                            date: selectedDate,
                            time: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            isCompleted: false,
                            assignedUserId: selectedUserId,
                          );
                          onTodoCreated(todo);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please enter a todo title'),
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
                        'Create Todo',
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
          );
        },
      ),
    );
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
  }) {
    return TextField(
      controller: controller,
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
      ),
    );
  }
}
