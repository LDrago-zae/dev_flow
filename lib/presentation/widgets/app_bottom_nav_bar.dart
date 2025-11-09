import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:dev_flow/core/constants/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const AppBottomNavBar({super.key, required this.selectedIndex});

  void _onTabChange(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/activity');
        break;
      case 2:
        context.go('/reports');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Colors.black,
        border: Border(
          top: BorderSide(color: DarkThemeColors.surface, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
            curve: Curves.easeInOut,
            selectedIndex: selectedIndex,
            onTabChange: (index) => _onTabChange(context, index),
            gap: 8,
            activeColor: isDark
                ? DarkThemeColors.primary100
                : LightThemeColors.primary300,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: isDark
                ? DarkThemeColors.surface
                : LightThemeColors.primary300.withOpacity(0.1),
            color: isDark
                ? DarkThemeColors.textSecondary
                : LightThemeColors.textSecondary,
            tabs: const [
              GButton(icon: Icons.home_outlined, text: 'Home'),
              GButton(icon: Icons.show_chart_outlined, text: 'Activity'),
              GButton(icon: Icons.assessment_outlined, text: 'Reports'),
              GButton(icon: Icons.person_outline, text: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
