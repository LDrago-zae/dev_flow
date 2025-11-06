import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';

class FabOptionsDialog extends StatelessWidget {
  final VoidCallback onAddProject;
  final VoidCallback onAddQuickTodo;

  const FabOptionsDialog({
    super.key,
    required this.onAddProject,
    required this.onAddQuickTodo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DarkThemeColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'What would you like to add?',
            style: TextStyle(
              color: DarkThemeColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _OptionButton(
                  icon: Icons.folder_special,
                  label: 'New Project',
                  onTap: () {
                    Navigator.pop(context);
                    onAddProject();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OptionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Quick Todo',
                  onTap: () {
                    Navigator.pop(context);
                    onAddQuickTodo();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: DarkThemeColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DarkThemeColors.border),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: DarkThemeColors.primary100,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: DarkThemeColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
