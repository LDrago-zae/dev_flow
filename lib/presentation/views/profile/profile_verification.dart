import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
// import '../signin/signin.dart';

class ProfileVerification extends StatefulWidget {
  const ProfileVerification({super.key});

  @override
  State<ProfileVerification> createState() => _ProfileVerificationState();
}

class _ProfileVerificationState extends State<ProfileVerification> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkThemeColors.dark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Logo Bar
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/Logo.svg',
                    height: 40,
                    width: 40,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'DevFlow',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 140),
            // Centered Success Image
            SvgPicture.asset(
              'assets/images/Succes.svg',
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 20),
            Text(
              'Verification Successful!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: DarkThemeColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              maxLines: 2,
              'Your profile has been successfully created',
              style: AppTextStyles.bodySmall.copyWith(
                color: DarkThemeColors.textSecondary,
                // fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            Spacer(),
            // const SizedBox(height: 135),
            // Centered Continue Button
            SizedBox(
              width: 320,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DarkThemeColors.primary100,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Get.offAll(() => const SignIn());
                },
                child: Text(
                  'Go to Home Page',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
