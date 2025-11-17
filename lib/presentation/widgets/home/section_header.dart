import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final bool isDark;
  final bool showAction;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText = 'See All',
    required this.isDark,
    this.showAction = true,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final showActionText = showAction && (actionText?.isNotEmpty ?? false);

    return Row(
      mainAxisAlignment: showActionText
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark
                ? DarkThemeColors.textPrimary
                : LightThemeColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (showActionText)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText!,
              style: TextStyle(
                color: isDark
                    ? DarkThemeColors.primary100
                    : LightThemeColors.primary300,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
