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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPeriod,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: const Color(0xFF0B0B0B),
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF101010),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1F1F1F), width: 1),
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: DarkThemeColors.textPrimary,
              size: 18,
            ),
          ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          selectedItemBuilder: (context) {
            return periods.map((period) {
              return Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: DarkThemeColors.primary100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    period,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: periods.map((String period) {
            return DropdownMenuItem<String>(
              value: period,
              child: Row(
                children: [
                  Icon(
                    period == selectedPeriod
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: period == selectedPeriod
                        ? DarkThemeColors.primary100
                        : DarkThemeColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    period,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: period == selectedPeriod
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onPeriodChanged(value);
            }
          },
        ),
      ),
    );
  }
}
