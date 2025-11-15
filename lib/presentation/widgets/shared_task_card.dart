import 'package:flutter/material.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:intl/intl.dart';

class SharedTaskCard extends StatelessWidget {
  final Task task;
  final Color projectColor;
  final String sharedByEmail;
  final String sharedWithEmail;
  final VoidCallback onTap;
  final Function(bool?)? onCheckboxChanged;

  const SharedTaskCard({
    super.key,
    required this.task,
    required this.projectColor,
    required this.sharedByEmail,
    required this.sharedWithEmail,
    required this.onTap,
    this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Create diagonal gradient
    final secondaryColor = _getComplementaryColor(projectColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              projectColor.withOpacity(0.15),
              secondaryColor.withOpacity(0.15),
            ],
            stops: const [0.3, 1.0],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: projectColor.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? projectColor
                            : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      color: task.isCompleted
                          ? projectColor
                          : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),

                  const SizedBox(width: 12),

                  // Task content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          task.title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),

                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            task.description!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Date and priority
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getDateColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _getDateColor().withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 12,
                                    color: _getDateColor(),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM dd').format(task.date),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: _getDateColor(),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (task.priority != null &&
                                task.priority!.toLowerCase() != 'low')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor().withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _getPriorityColor().withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.flag_rounded,
                                      size: 12,
                                      color: _getPriorityColor(),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.priority!.toUpperCase(),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: _getPriorityColor(),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Shared badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: projectColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: projectColor.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.people_outline_rounded,
                      size: 16,
                      color: projectColor,
                    ),
                  ),
                ],
              ),
            ),

            // Sharing info footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: projectColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // From tag
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'From: ${_extractUsername(sharedByEmail)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Separator
                  Container(
                    width: 1,
                    height: 12,
                    color: Colors.white.withOpacity(0.2),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),

                  // To tag
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'To: ${_extractUsername(sharedWithEmail)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getComplementaryColor(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor
        .withLightness((hslColor.lightness + 0.15).clamp(0.0, 1.0))
        .toColor();
  }

  Color _getDateColor() {
    // Simple white color for dates
    return Colors.white;
  }

  Color _getPriorityColor() {
    if (task.priority == null) return Colors.white.withOpacity(0.7);

    switch (task.priority!.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.white.withOpacity(0.7);
    }
  }

  String _extractUsername(String email) {
    return email.split('@').first;
  }
}
