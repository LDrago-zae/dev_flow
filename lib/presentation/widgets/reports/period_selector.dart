import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';

class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final List<String> periods;
  final Function(String) onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.periods,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: DropdownButton<String>(
        value: selectedPeriod,
        onChanged: (value) {
          if (value != null) {
            onPeriodChanged(value);
          }
        },
        items: periods.map((String period) {
          return DropdownMenuItem<String>(
            value: period,
            child: Text(
              period,
              style: AppTextStyles.bodyMedium.copyWith(
                color: DarkThemeColors.textPrimary,
              ),
            ),
          );
        }).toList(),
        dropdownColor: DarkThemeColors.surface,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: DarkThemeColors.textSecondary,
        ),
        underline: const SizedBox(),
        style: AppTextStyles.bodyMedium.copyWith(
          color: DarkThemeColors.textPrimary,
        ),
      ),
    );
  }
}
