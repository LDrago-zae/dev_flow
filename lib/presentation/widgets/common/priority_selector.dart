import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/project_model.dart';

class PrioritySelector extends StatelessWidget {
  final ProjectPriority selectedPriority;
  final Function(ProjectPriority) onPrioritySelected;
  final String? label;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onPrioritySelected,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: DarkThemeColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            _buildPriorityChip('High', ProjectPriority.high, Colors.red),
            const SizedBox(width: 12),
            _buildPriorityChip('Medium', ProjectPriority.medium, Colors.orange),
            const SizedBox(width: 12),
            _buildPriorityChip('Low', ProjectPriority.low, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityChip(
    String label,
    ProjectPriority priority,
    Color color,
  ) {
    final isSelected = priority == selectedPriority;
    return Expanded(
      child: GestureDetector(
        onTap: () => onPrioritySelected(priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.2)
                : DarkThemeColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : DarkThemeColors.border,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? color : DarkThemeColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
