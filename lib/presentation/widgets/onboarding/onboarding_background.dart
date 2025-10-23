import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingBackground extends StatelessWidget {
  final Animation<Offset> imageSlideAnimation;
  final Animation<double> imageFadeAnimation;
  final Animation<Offset> pageImageSlideAnimation;
  final Animation<double> pageImageFadeAnimation;
  final String currentImage;
  final int currentPage;

  const OnboardingBackground({
    super.key,
    required this.imageSlideAnimation,
    required this.imageFadeAnimation,
    required this.pageImageSlideAnimation,
    required this.pageImageFadeAnimation,
    required this.currentImage,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: LightThemeColors.primary600,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: imageSlideAnimation,
              child: FadeTransition(
                opacity: imageFadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 300.0),
                  child: SlideTransition(
                    position: pageImageSlideAnimation,
                    child: FadeTransition(
                      opacity: pageImageFadeAnimation,
                      child: Image.asset(
                        currentImage,
                        width: 350,
                        height: 350,
                        key: ValueKey(currentPage),
                      ),
                    ),
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
