import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/presentation/widgets/user_dropdown.dart';

class AddEditTaskDialog {
  static void show(
    BuildContext context, {
    Task? task,
    required DateTime initialDate,
    required TimeOfDay initialTime,
    required Function(
      String title,
      DateTime date,
      TimeOfDay time,
      String? assignedUserId,
    )
    onSubmit,
  }) {
    final titleController = TextEditingController(text: task?.title ?? '');
    DateTime selectedDate = task?.date ?? initialDate;
    TimeOfDay selectedTime = initialTime;
    String? selectedUserId = task?.assignedUserId;
    final bool isEditing = task != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: DarkThemeColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit Task' : 'Add New Task',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: DarkThemeColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Task title',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: DarkThemeColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: DarkThemeColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  UserDropdown(
                    selectedUserId: selectedUserId,
                    onUserSelected: (userId) {
                      setModalState(() {
                        selectedUserId = userId;
                      });
                    },
                    hintText: 'Assign task to user',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(context, selectedDate, (date) {
                          setModalState(() {
                            selectedDate = date;
                          });
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimePicker(context, selectedTime, (time) {
                          setModalState(() {
                            selectedTime = time;
                          });
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.trim().isNotEmpty) {
                          onSubmit(
                            titleController.text.trim(),
                            selectedDate,
                            selectedTime,
                            selectedUserId,
                          );
                          Navigator.pop(context);
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
                        isEditing ? 'Update Task' : 'Add Task',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildDatePicker(
    BuildContext context,
    DateTime selectedDate,
    Function(DateTime) onDateSelected,
  ) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onDateSelected(date);
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
              style: AppTextStyles.bodyMedium.copyWith(
                color: DarkThemeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTimePicker(
    BuildContext context,
    TimeOfDay selectedTime,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (time != null) {
          onTimeSelected(time);
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
              style: AppTextStyles.bodyMedium.copyWith(
                color: DarkThemeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
