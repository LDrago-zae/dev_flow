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
        context.go('/news');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;

        // Adjust spacing and padding based on screen size - very compact for mobile
        final horizontalPadding = isMobile ? 16.0 : 32.0;
        final verticalPadding = isMobile ? 16.0 : 24.0;
        final gap = isMobile ? 0.0 : 8.0;
        final iconSize = isMobile ? 20.0 : 24.0;
        final buttonPadding = isMobile
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
            : const EdgeInsets.symmetric(horizontal: 32, vertical: 16);

        // Hide text labels on mobile to prevent overflow
        final showText = !isMobile;

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
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: GNav(
                curve: Curves.easeInOut,
                selectedIndex: selectedIndex,
                onTabChange: (index) => _onTabChange(context, index),
                gap: gap,
                activeColor: isDark
                    ? DarkThemeColors.primary100
                    : LightThemeColors.primary300,
                iconSize: iconSize,
                padding: buttonPadding,
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: isDark
                    ? DarkThemeColors.surface
                    : LightThemeColors.primary300.withOpacity(0.1),
                color: isDark
                    ? DarkThemeColors.textSecondary
                    : LightThemeColors.textSecondary,
                tabs: [
                  GButton(
                    icon: Icons.home_outlined,
                    text: showText ? 'Home' : '',
                  ),
                  GButton(
                    icon: Icons.show_chart_outlined,
                    text: showText ? 'Activity' : '',
                  ),
                  GButton(
                    icon: Icons.assessment_outlined,
                    text: showText ? 'Reports' : '',
                  ),
                  GButton(
                    icon: Icons.article_outlined,
                    text: showText ? 'News' : '',
                  ),
                  GButton(
                    icon: Icons.person_outline,
                    text: showText ? 'Profile' : '',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
