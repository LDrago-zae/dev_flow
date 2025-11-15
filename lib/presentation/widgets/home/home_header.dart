import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/services/notification_service.dart';
import 'package:go_router/go_router.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final bool isDark;

  const HomeHeader({super.key, required this.userName, required this.isDark});

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
        // Notification Icon with Badge
        StreamBuilder<int>(
          stream: NotificationService().watchUnreadCount(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;

            return GestureDetector(
              onTap: () {
                context.push('/notifications');
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? DarkThemeColors.surface
                      : LightThemeColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? DarkThemeColors.border
                        : LightThemeColors.border,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: isDark
                          ? DarkThemeColors.icon
                          : LightThemeColors.icon,
                      size: 24,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
