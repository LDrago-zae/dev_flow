import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/subtask_model.dart';

class SubtaskListWidget extends StatelessWidget {
  final List<Subtask> subtasks;
  final Color projectCardColor;
  final Function(String, bool) onToggleSubtask;
  final Function(String) onDeleteSubtask;

  const SubtaskListWidget({
    super.key,
    required this.subtasks,
    required this.projectCardColor,
    required this.onToggleSubtask,
    required this.onDeleteSubtask,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 8, right: 40),
      child: Column(
        children: subtasks.map((subtask) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _buildCheckbox(subtask),
                const SizedBox(width: 12),
                Expanded(child: _buildSubtaskTitle(subtask)),
                _buildDeleteButton(subtask),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCheckbox(Subtask subtask) {
    return GestureDetector(
      onTap: () => onToggleSubtask(subtask.id, !subtask.isCompleted),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: subtask.isCompleted
                ? projectCardColor
                : DarkThemeColors.border,
            width: 2,
          ),
          color: subtask.isCompleted ? projectCardColor : Colors.transparent,
        ),
        child: subtask.isCompleted
            ? const Icon(Icons.check, size: 12, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildSubtaskTitle(Subtask subtask) {
    return Text(
      subtask.title,
      style: AppTextStyles.bodySmall.copyWith(
        color: subtask.isCompleted
            ? DarkThemeColors.textSecondary
            : DarkThemeColors.textPrimary,
        decoration: subtask.isCompleted
            ? TextDecoration.lineThrough
            : TextDecoration.none,
      ),
    );
  }

  Widget _buildDeleteButton(Subtask subtask) {
    return IconButton(
      icon: Icon(
        Icons.delete_outline,
        size: 16,
        color: DarkThemeColors.textSecondary,
      ),
      onPressed: () => onDeleteSubtask(subtask.id),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: 'Delete subtask',
    );
  }
}
