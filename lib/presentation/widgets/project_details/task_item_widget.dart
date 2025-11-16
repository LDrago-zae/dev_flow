import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/data/models/subtask_model.dart';
import 'package:dev_flow/data/models/user_model.dart';
import 'package:dev_flow/presentation/widgets/user_avatar.dart';
import 'subtask_list_widget.dart';

class TaskItemWidget extends StatelessWidget {
  final Task task;
  final Color projectCardColor;
  final VoidCallback onToggleCompletion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddSubtask;
  final bool isAddingSubtask;
  final TextEditingController subtaskController;
  final Function(String) onSubtaskSubmit;
  final List<Subtask>? subtasks;
  final Function(String, bool) onToggleSubtask;
  final Function(String) onDeleteSubtask;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.projectCardColor,
    required this.onToggleCompletion,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSubtask,
    required this.isAddingSubtask,
    required this.subtaskController,
    required this.onSubtaskSubmit,
    this.subtasks,
    required this.onToggleSubtask,
    required this.onDeleteSubtask,
  });

  @override
  Widget build(BuildContext context) {
    final dateString = _formatDate(task.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Dismissible(
            key: Key(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) => onDelete(),
            child: Row(
              children: [
                _buildCheckbox(),
                const SizedBox(width: 16),
                Expanded(child: _buildTaskInfo(dateString)),
                _buildAddSubtaskButton(),
                const SizedBox(width: 8),
                _buildEditButton(),
                const SizedBox(width: 8),
                _buildUserAvatar(),
              ],
            ),
          ),
          // Subtask input field
          if (isAddingSubtask) _buildSubtaskInput(context),
          // Display subtasks
          if (subtasks != null && subtasks!.isNotEmpty)
            SubtaskListWidget(
              subtasks: subtasks!,
              projectCardColor: projectCardColor,
              onToggleSubtask: onToggleSubtask,
              onDeleteSubtask: onDeleteSubtask,
            ),
        ],
      ),
    );
  }

  Widget _buildCheckbox() {
    return GestureDetector(
      onTap: onToggleCompletion,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: task.isCompleted ? projectCardColor : DarkThemeColors.border,
            width: 2,
          ),
          color: task.isCompleted ? projectCardColor : Colors.transparent,
        ),
        child: task.isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildTaskInfo(String dateString) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: task.isCompleted
                ? DarkThemeColors.textSecondary
                : DarkThemeColors.textPrimary,
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              dateString,
              style: AppTextStyles.bodySmall.copyWith(
                color: DarkThemeColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'at',
              style: AppTextStyles.bodySmall.copyWith(
                color: DarkThemeColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              task.time,
              style: AppTextStyles.bodySmall.copyWith(
                color: DarkThemeColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddSubtaskButton() {
    return IconButton(
      icon: Icon(
        isAddingSubtask ? Icons.close : Icons.add,
        size: 20,
        color: DarkThemeColors.textSecondary,
      ),
      onPressed: onAddSubtask,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: 'Add subtask',
    );
  }

  Widget _buildEditButton() {
    return IconButton(
      icon: Icon(Icons.edit, size: 20, color: DarkThemeColors.textSecondary),
      onPressed: onEdit,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildUserAvatar() {
    return UserAvatar(
      user: task.assignedUserId != null
          ? DummyUsers.getUserById(task.assignedUserId!)
          : null,
      radius: 16,
    );
  }

  Widget _buildSubtaskInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 8, right: 40),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: subtaskController,
              style: AppTextStyles.bodySmall.copyWith(
                color: DarkThemeColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Enter subtask title...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: DarkThemeColors.textSecondary,
                ),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => onSubtaskSubmit(task.id),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, size: 20),
            color: projectCardColor,
            onPressed: () => onSubtaskSubmit(task.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const monthNames = [
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
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }
}
