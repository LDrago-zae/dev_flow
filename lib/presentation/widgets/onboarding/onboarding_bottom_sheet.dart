import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'onboarding_page_content.dart';
import 'page_indicator.dart';
import 'onboarding_buttons.dart';

class OnboardingBottomSheet extends StatelessWidget {
  final PageController pageController;
  final int totalPages;
  final int currentPage;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final Function(int) onPageChanged;

  const OnboardingBottomSheet({
    super.key,
    required this.pageController,
    required this.totalPages,
    required this.currentPage,
    required this.onNext,
    required this.onSkip,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
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
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    children: const [
                      OnboardingPageContent(
                        title: 'Effortless Task Management',
                        description:
                            'Organize your tasks efficiently with our intuitive interface designed for developers.',
                      ),
                      OnboardingPageContent(
                        title: 'Boost Your Productivity',
                        description:
                            'Track your progress and stay focused with powerful tools built for your workflow.',
                      ),
                      OnboardingPageContent(
                        title: 'Collaborate Seamlessly',
                        description:
                            'Work together with your team and share updates in real-time.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Page indicator
                OnboardingPageIndicator(
                  controller: pageController,
                  count: totalPages,
                ),

                const SizedBox(height: 32),

                // Action buttons
                OnboardingButtons(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  onNext: onNext,
                  onSkip: onSkip,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
