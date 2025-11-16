import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/presentation/widgets/user_avatar.dart';
import 'package:dev_flow/data/models/user_model.dart';
import 'package:dev_flow/presentation/views/activity/daily_task_detail_screen.dart';

class KanbanBoardWidget extends StatelessWidget {
  final List<Task> tasks;
  final Color projectCardColor;
  final void Function(Task) onToggleCompletion;

  const KanbanBoardWidget({
    super.key,
    required this.tasks,
    required this.projectCardColor,
    required this.onToggleCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final todoTasks = tasks.where((t) => !t.isCompleted).toList();
    final doneTasks = tasks.where((t) => t.isCompleted).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildColumn(context, 'Todo', todoTasks, isDoneColumn: false),
            const SizedBox(height: 16),
            _buildColumn(context, 'Done', doneTasks, isDoneColumn: true),
          ],
        );

        // If the parent gives us a bounded height (e.g. inside a fixed panel),
        // make the Kanban content scrollable to avoid RenderFlex overflow.
        // When used inside an outer SingleChildScrollView (unbounded height),
        // we just return the plain Column so the page scrolls normally.
        if (constraints.hasBoundedHeight) {
          return SingleChildScrollView(child: content);
        }

        return content;
      },
    );
  }

  Widget _buildColumn(
    BuildContext context,
    String title,
    List<Task> columnTasks, {
    required bool isDoneColumn,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DarkThemeColors.border.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: DarkThemeColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DarkThemeColors.border.withOpacity(0.7),
                  ),
                ),
                child: Text(
                  '${columnTasks.length}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: DarkThemeColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DragTarget<Task>(
            onWillAccept: (task) {
              if (task == null) return false;
              return task.isCompleted != isDoneColumn;
            },
            onAccept: (task) {
              if (task.isCompleted != isDoneColumn) {
                onToggleCompletion(task);
              }
            },
            builder: (context, candidateData, rejectedData) {
              if (columnTasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No tasks',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: DarkThemeColors.textSecondary,
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: columnTasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 260,
                        child: _buildDraggableTaskCard(context, task),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableTaskCard(BuildContext context, Task task) {
    return LongPressDraggable<Task>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Opacity(opacity: 0.9, child: _buildTaskCard(context, task)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildTaskCard(context, task),
      ),
      child: _buildTaskCard(context, task),
    );
  }

  void _showQuickActions(BuildContext context, Task task) {
    final isCompleted = task.isCompleted;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    isCompleted
                        ? Icons.undo_rounded
                        : Icons.check_circle_rounded,
                    color: Colors.white,
                  ),
                  title: Text(
                    isCompleted ? 'Move to Todo' : 'Move to Completed',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onToggleCompletion(task);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final dateString = '${task.date.day}/${task.date.month}/${task.date.year}';
    final priorityText = _getPriorityLabel(task.priority);
    final priorityColor = _getPriorityColor(task.priority);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => DailyTaskDetailScreen(task: task),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: task.isCompleted
                ? projectCardColor.withOpacity(0.7)
                : DarkThemeColors.border.withOpacity(0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: projectCardColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.dashboard_customize_rounded,
                    size: 16,
                    color: projectCardColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: DarkThemeColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: DarkThemeColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Deadline',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: DarkThemeColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              dateString,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: DarkThemeColors.textPrimary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (priorityText != null)
                        Row(
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 14,
                              color: priorityColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Priority',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: DarkThemeColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              priorityText,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: priorityColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      if (task.category != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              size: 14,
                              color: DarkThemeColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Category',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: DarkThemeColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                task.category!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: DarkThemeColors.textPrimary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (task.assignedUserId != null) ...[
                  const SizedBox(width: 8),
                  UserAvatar(
                    user: DummyUsers.getUserById(task.assignedUserId!),
                    radius: 14,
                  ),
                ],
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _showQuickActions(context, task),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: DarkThemeColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => onToggleCompletion(task),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: task.isCompleted ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: task.isCompleted
                        ? Colors.green
                        : DarkThemeColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      task.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: task.isCompleted
                          ? Colors.white
                          : DarkThemeColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.isCompleted ? 'Done' : 'Mark as done',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: task.isCompleted
                            ? Colors.white
                            : DarkThemeColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.orangeAccent;
      case 'medium':
        return Colors.yellowAccent.shade700;
      case 'low':
        return Colors.greenAccent;
      default:
        return DarkThemeColors.textSecondary;
    }
  }

  String? _getPriorityLabel(String? priority) {
    if (priority == null) return null;
    switch (priority) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return priority;
    }
  }
}
