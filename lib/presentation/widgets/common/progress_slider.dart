import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';

class ProgressSlider extends StatelessWidget {
  final double value;
  final Function(double) onChanged;
  final String? label;

  const ProgressSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: DarkThemeColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: DarkThemeColors.primary100,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: DarkThemeColors.primary100,
            inactiveTrackColor: DarkThemeColors.border,
            thumbColor: DarkThemeColors.primary100,
            overlayColor: DarkThemeColors.primary100.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 100,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
