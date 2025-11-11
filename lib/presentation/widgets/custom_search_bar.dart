import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final Widget? suffixIcon;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search your project',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.controller,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DarkThemeColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: isDark ? DarkThemeColors.icon : LightThemeColors.icon,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                style: TextStyle(
                  color: isDark
                      ? DarkThemeColors.textPrimary
                      : LightThemeColors.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: isDark
                        ? DarkThemeColors.textSecondary
                        : LightThemeColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: suffixIcon,
                  suffixIconConstraints: const BoxConstraints(
                    minHeight: 24,
                    minWidth: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
