import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../view_models/onboarding/onboarding_viewmodel.dart';
import '../../widgets/onboarding/onboarding_background.dart';
import '../../widgets/onboarding/onboarding_bottom_sheet.dart';

class Onboarding extends GetView<OnboardingViewModel> {
  const Onboarding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Obx(
            () => OnboardingBackground(
              imageSlideAnimation: controller.imageSlideAnimation,
              imageFadeAnimation: controller.imageFadeAnimation,
              pageImageSlideAnimation: controller.pageImageSlideAnimation,
              pageImageFadeAnimation: controller.pageImageFadeAnimation,
              currentImage: controller.currentImage,
              currentPage: controller.currentPage.value,
            ),
          ),
          Obx(
            () => OnboardingBottomSheet(
              pageController: controller.pageController,
              totalPages: controller.totalPages,
              currentPage: controller.currentPage.value,
              onNext: () => controller.nextPage(context),
              onSkip: () => controller.skipToGetStarted(context),
              onPageChanged: controller.onPageChanged,
            ),
          ),
        ],
      ),
    );
  }
}
