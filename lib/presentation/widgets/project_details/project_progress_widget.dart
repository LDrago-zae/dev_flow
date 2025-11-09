import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';

class ProjectProgressWidget extends StatelessWidget {
  final double progress;
  final int completedTasks;
  final int totalTasks;

  const ProjectProgressWidget({
    super.key,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DarkThemeColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Project Progress',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: DarkThemeColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: DarkThemeColors.primary100,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: DarkThemeColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                DarkThemeColors.primary100,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$completedTasks of $totalTasks tasks completed',
            style: AppTextStyles.bodySmall.copyWith(
              color: DarkThemeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
