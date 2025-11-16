import 'package:flutter/material.dart';

class AppAnimations {
  // Fade in animation from bottom
  static Animation<Offset> fadeInUp(
    AnimationController controller, {
    double offset = 0.5,
  }) {
    return Tween<Offset>(
      begin: Offset(0, offset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
  }

  // Fade out animation to top
  static Animation<Offset> fadeOutUp(
    AnimationController controller, {
    double offset = 0.5,
  }) {
    return Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, -offset),
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInCubic));
  }

  // Slide in from right
  static Animation<Offset> slideInRight(
    AnimationController controller, {
    double offset = 0.5,
  }) {
    return Tween<Offset>(
      begin: Offset(offset, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
  }

  // Slide out to left
  static Animation<Offset> slideOutLeft(
    AnimationController controller, {
    double offset = 0.5,
  }) {
    return Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-offset, 0),
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInCubic));
  }

  // Fade in animation
  static Animation<double> fadeIn(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOutQuart),
    );
  }

  // Fade out animation
  static Animation<double> fadeOut(AnimationController controller) {
    return Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOutQuart),
    );
  }

  // Scale in animation
  static Animation<double> scaleIn(
    AnimationController controller, {
    double begin = 0.8,
    double end = 1.0,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
  }

  // Scale out animation
  static Animation<double> scaleOut(
    AnimationController controller, {
    double begin = 1.0,
    double end = 0.8,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInBack));
  }

  // Bounce animation
  static Animation<double> bounce(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
  }

  // Staggered animation for lists
  static Animation<Offset> staggeredItemAnimation(
    AnimationController controller,
    int index,
    int itemCount, {
    double offset = 0.2,
  }) {
    final double start = (index + 1) * (1.0 / itemCount);
    final double end = start + (1.0 / itemCount);

    return Tween<Offset>(begin: Offset(0, offset), end: Offset.zero).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOutQuart),
      ),
    );
  }

  // Page transition animation
  static PageRouteBuilder<T> createPageRoute<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    bool fade = true,
    bool slide = true,
    Offset beginOffset = const Offset(1.0, 0.0),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        if (fade && slide) {
          return FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: beginOffset,
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        } else if (fade) {
          return FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          );
        } else if (slide) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          );
        }

        return child;
      },
    );
  }
}

// Animation extension for easy usage on any widget
extension AnimationExtension on Widget {
  // Apply fade in animation
  Widget fadeIn(AnimationController controller) {
    return FadeTransition(
      opacity: AppAnimations.fadeIn(controller),
      child: this,
    );
  }

  // Apply fade in up animation
  Widget fadeInUp(AnimationController controller, {double offset = 0.5}) {
    return SlideTransition(
      position: AppAnimations.fadeInUp(controller, offset: offset),
      child: FadeTransition(
        opacity: AppAnimations.fadeIn(controller),
        child: this,
      ),
    );
  }

  // Apply scale in animation
  Widget scaleIn(AnimationController controller, {double begin = 0.8}) {
    return ScaleTransition(
      scale: AppAnimations.scaleIn(controller, begin: begin),
      child: this,
    );
  }

  // Apply bounce animation
  Widget bounce(AnimationController controller) {
    return ScaleTransition(
      scale: AppAnimations.bounce(controller),
      child: this,
    );
  }
}
