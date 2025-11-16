import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? DarkThemeColors.primary100
                    : LightThemeColors.primary300)
              : DarkThemeColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark
                      ? DarkThemeColors.primary100
                      : LightThemeColors.primary300)
                : (isDark ? DarkThemeColors.border : LightThemeColors.border),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark
                      ? DarkThemeColors.textPrimary
                      : LightThemeColors.textPrimary),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
