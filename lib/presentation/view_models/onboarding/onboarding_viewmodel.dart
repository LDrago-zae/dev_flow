import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/app_routes.dart';

class OnboardingViewModel extends GetxController with GetTickerProviderStateMixin {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  final int totalPages = 3;

  late AnimationController animationController;
  late AnimationController pageTransitionController;
  late Animation<Offset> imageSlideAnimation;
  late Animation<double> imageFadeAnimation;
  late Animation<Offset> pageImageSlideAnimation;
  late Animation<double> pageImageFadeAnimation;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    imageSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));

    imageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeIn),
    );

    pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    pageImageSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: pageTransitionController,
      curve: Curves.easeOut,
    ));

    pageImageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: pageTransitionController, curve: Curves.easeIn),
    );

    animationController.forward();
    pageTransitionController.value = 1.0;
  }

  String get currentImage {
    switch (currentPage.value) {
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

  void nextPage(BuildContext context) {
    if (currentPage.value < totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      navigateToGetStarted(context);
    }
  }

  void skipToGetStarted(BuildContext context) {
    navigateToGetStarted(context);
  }

  void navigateToGetStarted(BuildContext context) {
    context.go(AppRoutes.getStarted);
  }

  void onPageChanged(int index) {
    currentPage.value = index;
    pageTransitionController.reset();
    pageTransitionController.forward();
  }

  @override
  void onClose() {
    animationController.dispose();
    pageTransitionController.dispose();
    pageController.dispose();
    super.onClose();
  }
}
