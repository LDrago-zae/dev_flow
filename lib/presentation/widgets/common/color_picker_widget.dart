import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';

class ColorPickerWidget extends StatelessWidget {
  final List<Color> colors;
  final Color selectedColor;
  final Function(Color) onColorSelected;
  final String? label;

  const ColorPickerWidget({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    this.label,
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
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final isSelected = color.value == selectedColor.value;
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
