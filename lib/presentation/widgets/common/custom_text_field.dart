import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final int maxLines;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: DarkThemeColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTextStyles.bodyMedium.copyWith(
            color: DarkThemeColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: DarkThemeColors.textSecondary,
            ),
            filled: true,
            fillColor: DarkThemeColors.background,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: DarkThemeColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: DarkThemeColors.primary100,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
