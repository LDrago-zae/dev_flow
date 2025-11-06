import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final bool isDark;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    required this.actionText,
    required this.isDark,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark
                ? DarkThemeColors.textPrimary
                : LightThemeColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Text(
            actionText,
            style: TextStyle(
              color: isDark
                  ? DarkThemeColors.primary100
                  : LightThemeColors.primary300,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
