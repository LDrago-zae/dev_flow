import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/user_model.dart';

class UserAvatar extends StatelessWidget {
  final User? user;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: DarkThemeColors.surface,
          child: Icon(
            Icons.person,
            color: DarkThemeColors.textSecondary,
            size: radius * 0.8,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: _getAvatarColor(user!.id),
        child: user!.avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  user!.avatarUrl!,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      DummyUsers.getInitials(user!.name),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: radius * 0.6,
                      ),
                    );
                  },
                ),
              )
            : Text(
                DummyUsers.getInitials(user!.name),
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: radius * 0.6,
                ),
              ),
      ),
    );
  }

  Color _getAvatarColor(String userId) {
    // Generate consistent colors based on user ID
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final hash = userId.hashCode;
    return colors[hash % colors.length];
  }
}
