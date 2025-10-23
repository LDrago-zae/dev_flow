import 'package:get/get.dart';
import '../presentation/bindings/onboarding/onboarding_binding.dart';
import '../presentation/views/onboarding/onboarding.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';

  static final routes = [
    GetPage(
      name: onboarding,
      page: () => const Onboarding(),
      binding: OnboardingBinding(),
    ),
  ];
}
