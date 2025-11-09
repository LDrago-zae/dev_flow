import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';

class ReportDetailCard extends StatelessWidget {
  final String title;
  final int value;
  final String subtitle;
  final Color accentColor;

  const ReportDetailCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: DarkThemeColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: AppTextStyles.headlineLarge.copyWith(
              color: accentColor,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: DarkThemeColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
