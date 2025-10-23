import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_text_styles.dart';

class GetStarted extends StatelessWidget {
  const GetStarted({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkThemeColors.background,
      appBar: AppBar(
        backgroundColor: DarkThemeColors.background,
        elevation: 0,
        title: Text(
          'Get Started',
          style: AppTextStyles.headlineSmall.copyWith(
            color: DarkThemeColors.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 100,
                color: LightThemeColors.primary200,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to DevFlow!',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: DarkThemeColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You\'re all set to start your development journey.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: DarkThemeColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  // Navigate to main app
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: LightThemeColors.primary600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
