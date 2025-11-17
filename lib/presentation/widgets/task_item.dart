import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TaskItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String time;
  final VoidCallback? onTap;
  final VoidCallback? onCheckboxTap;
  final bool isCompleted;
  final Color? checkboxColor;
  final VoidCallback? onTimerTap;
  final bool isTimerActive;
  final String? timerDuration;

  const TaskItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.time,
    this.onTap,
    this.onCheckboxTap,
    this.isCompleted = false,
    this.checkboxColor,
    this.onTimerTap,
    this.isTimerActive = false,
    this.timerDuration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveCheckboxColor = checkboxColor ?? DarkThemeColors.primary100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DarkThemeColors.border),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: onCheckboxTap ?? onTap,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? effectiveCheckboxColor
                        : DarkThemeColors.border,
                    width: 2,
                  ),
                  color: isCompleted
                      ? effectiveCheckboxColor
                      : Colors.transparent,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isCompleted
                          ? DarkThemeColors.textSecondary
                          : (isDark
                                ? DarkThemeColors.textPrimary
                                : LightThemeColors.textPrimary),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? DarkThemeColors.textSecondary
                          : LightThemeColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: isDark
                            ? DarkThemeColors.textSecondary
                            : LightThemeColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(
                          color: isDark
                              ? DarkThemeColors.textSecondary
                              : LightThemeColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isDark
                        ? DarkThemeColors.textSecondary
                        : LightThemeColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (onTimerTap != null && !isCompleted) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onTimerTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isTimerActive
                            ? DarkThemeColors.primary100.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isTimerActive
                              ? DarkThemeColors.primary100
                              : DarkThemeColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isTimerActive
                                ? Icons.stop_circle_outlined
                                : Icons.play_circle_outline,
                            size: 16,
                            color: isTimerActive
                                ? DarkThemeColors.primary100
                                : DarkThemeColors.textSecondary,
                          ),
                          if (timerDuration != null && isTimerActive) ...[
                            const SizedBox(width: 4),
                            Text(
                              timerDuration!,
                              style: TextStyle(
                                color: DarkThemeColors.primary100,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
