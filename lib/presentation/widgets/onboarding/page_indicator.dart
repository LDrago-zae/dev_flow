import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/constants/app_colors.dart';

class OnboardingPageIndicator extends StatelessWidget {
  final PageController controller;
  final int count;

  const OnboardingPageIndicator({
    super.key,
    required this.controller,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return SmoothPageIndicator(
      controller: controller,
      count: count,
      effect: ExpandingDotsEffect(
        activeDotColor: LightThemeColors.primary200,
        dotColor: DarkThemeColors.border,
        dotHeight: 8,
        dotWidth: 8,
        expansionFactor: 3,
        spacing: 8,
      ),
    );
  }
}
