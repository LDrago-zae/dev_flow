import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../core/utils/app_text_styles.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/app_routes.dart';
import '../../bindings/onboarding/onboarding_binding.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Adjust duration as needed
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Navigate to onboarding after animation completes
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            OnboardingBinding().dependencies();
            context.go(AppRoutes.onboarding);
          }
        });
      }
    });

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/images/Logo.svg',
                  width: MediaQuery.of(context).size.width * 0.4,
                ),
                const SizedBox(height: 20),
                Text(
                  "DevFlow",
                  style: AppTextStyles.headlineSmall, // Use centralized style
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/lottie/loader.json',
                    width: MediaQuery.of(context).size.width * 0.4,
                    controller: _animationController,
                    onLoaded: (composition) {
                      // Set the duration based on the actual animation
                      _animationController.duration = composition.duration;
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to a simple loading indicator if Lottie fails
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 100,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: AppTextStyles.bodyMedium, // Use centralized style
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
