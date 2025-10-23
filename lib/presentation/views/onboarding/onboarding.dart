import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/animations/app_animations.dart';
import '../get_started/get_started.dart';
import '../../widgets/onboarding/onboarding_background.dart';
import '../../widgets/onboarding/onboarding_bottom_sheet.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final RxInt _currentPage = 0.obs;
  final int _totalPages = 3;
  late AnimationController _animationController;
  late AnimationController _pageTransitionController;
  late Animation<Offset> _imageSlideAnimation;
  late Animation<double> _imageFadeAnimation;
  late Animation<Offset> _pageImageSlideAnimation;
  late Animation<double> _pageImageFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _imageSlideAnimation = AppAnimations.fadeInUp(_animationController, offset: 0.3);
    _imageFadeAnimation = AppAnimations.fadeIn(_animationController);

    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pageImageSlideAnimation = AppAnimations.fadeInUp(_pageTransitionController, offset: 0.2);
    _pageImageFadeAnimation = AppAnimations.fadeIn(_pageTransitionController);

    _animationController.forward();
    _pageTransitionController.value = 1.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageTransitionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage.value < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.off(() => const GetStarted());
    }
  }

  void _skipToGetStarted() {
    Get.off(() => const GetStarted());
  }

  String get _currentImage {
    switch (_currentPage.value) {
      case 0:
        return 'assets/images/Illustration2.png';
      case 1:
        return 'assets/images/Illustration3.png';
      case 2:
        return 'assets/images/Illustration4.png';
      default:
        return 'assets/images/Illustration2.png';
    }
  }

  void _onPageChanged(int index) {
    _currentPage.value = index;
    _pageTransitionController.reset();
    _pageTransitionController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(
                () => OnboardingBackground(
              imageSlideAnimation: _imageSlideAnimation,
              imageFadeAnimation: _imageFadeAnimation,
              pageImageSlideAnimation: _pageImageSlideAnimation,
              pageImageFadeAnimation: _pageImageFadeAnimation,
              currentImage: _currentImage,
              currentPage: _currentPage.value,
            ),
          ),
          Obx(
                () => OnboardingBottomSheet(
              pageController: _pageController,
              totalPages: _totalPages,
              currentPage: _currentPage.value,
              onNext: _nextPage,
              onSkip: _skipToGetStarted,
              onPageChanged: _onPageChanged,
            ),
          ),
        ],
      ),
    );
  }
}
