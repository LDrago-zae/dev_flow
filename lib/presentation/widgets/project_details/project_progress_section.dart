import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/project_model.dart';

class ProjectProgressSection extends StatelessWidget {
  final Project project;

  const ProjectProgressSection({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: AppTextStyles.bodyMedium.copyWith(
            color: DarkThemeColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final completedWidth =
                        constraints.maxWidth * project.progress;
                    return Row(
                      children: [
                        Container(
                          width: completedWidth,
                          decoration: BoxDecoration(
                            color: project.cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        Expanded(
                          child: Container(color: DarkThemeColors.border),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${project.completedTasksCount}/${project.totalTasksCount} Task',
              style: AppTextStyles.bodyMedium.copyWith(
                color: DarkThemeColors.textSecondary,
              ),
            ),
            Text(
              '${(project.progress * 100).toInt()}%',
              style: AppTextStyles.bodyMedium.copyWith(
                color: DarkThemeColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
