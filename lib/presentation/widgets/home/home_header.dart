import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final bool isDark;
  final VoidCallback? onLogout;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.isDark,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $userName',
              style: TextStyle(
                color: isDark
                    ? DarkThemeColors.textSecondary
                    : LightThemeColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready to conquer your day?',
              style: TextStyle(
                color: isDark
                    ? DarkThemeColors.textPrimary
                    : LightThemeColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onLogout ?? () async {
            // Default logout behavior if no custom handler provided
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? DarkThemeColors.surface : LightThemeColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? DarkThemeColors.border : LightThemeColors.border,
              ),
            ),
            child: Icon(
              Icons.logout,
              color: isDark ? DarkThemeColors.icon : LightThemeColors.icon,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}
