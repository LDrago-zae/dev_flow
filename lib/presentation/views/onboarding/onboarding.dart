import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_text_styles.dart';
import '../../../core/utils/animations/app_animations.dart';
import '../get_started/get_started.dart';
import '../../widgets/onboarding/onboarding_page_content.dart';
import '../../widgets/onboarding/onboarding_buttons.dart';
import '../../widgets/onboarding/page_indicator.dart';

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
    // Initial animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _imageSlideAnimation = AppAnimations.fadeInUp(_animationController, offset: 0.3);
    _imageFadeAnimation = AppAnimations.fadeIn(_animationController);

    // Page transition animation controller
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pageImageSlideAnimation = AppAnimations.fadeInUp(_pageTransitionController, offset: 0.2);
    _pageImageFadeAnimation = AppAnimations.fadeIn(_pageTransitionController);

    // Start the initial animation
    _animationController.forward();
    _pageTransitionController.value = 1.0; // Start at fully visible for first page
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
      // Navigate to Get Started screen
      Get.off(() => const GetStarted());
    }
  }

  void _skipToGetStarted() {
    Get.off(() => const GetStarted());
  }

  // Get the current image based on page
  String get _currentImage {
    switch (_currentPage.value) {
      case 0:
        return 'assets/images/Illustration2.png'; // First page image
      case 1:
        return 'assets/images/Illustration3.png'; // Second page image
      case 2:
        return 'assets/images/Illustration4.png'; // Third page image
      default:
        return 'assets/images/Illustration2.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightThemeColors.primary600, // Blue background
      body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: LightThemeColors.primary600,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SlideTransition(
                      position: _imageSlideAnimation,
                      child: FadeTransition(
                        opacity: _imageFadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 300.0),
                          child: SlideTransition(
                            position: _pageImageSlideAnimation,
                            child: FadeTransition(
                              opacity: _pageImageFadeAnimation,
                              child: Obx(
                                    () => Image.asset(
                                  _currentImage,
                                  width: 350,
                                  height: 350,
                                  key: ValueKey(_currentPage.value), // Force rebuild on page change
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Non-draggable bottom sheet
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.5,
              maxChildSize: 0.5,
              shouldCloseOnMinExtent: false,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: DarkThemeColors.dark,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Handle indicator
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: DarkThemeColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // PageView with content
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              _currentPage.value = index;
                              // Trigger fade-up animation on page change
                              _pageTransitionController.reset();
                              _pageTransitionController.forward();
                            },
                            children: const [
                              // First page
                              OnboardingPageContent(
                                title: 'Effortless Task Management',
                                description: 'Organize your tasks efficiently with our intuitive interface designed for developers.',
                              ),
                              // Second page
                              OnboardingPageContent(
                                title: 'Boost Your Productivity',
                                description: 'Track your progress and stay focused with powerful tools built for your workflow.',
                              ),
                              // Third page
                              OnboardingPageContent(
                                title: 'Collaborate Seamlessly',
                                description: 'Work together with your team and share updates in real-time.',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Page indicator
                        OnboardingPageIndicator(
                          controller: _pageController,
                          count: _totalPages,
                        ),

                        const SizedBox(height: 32),

                        // Action buttons
                        Obx(
                              () => OnboardingButtons(
                            currentPage: _currentPage.value,
                            totalPages: _totalPages,
                            onNext: _nextPage,
                            onSkip: _skipToGetStarted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ]
      ),
    );
  }
}