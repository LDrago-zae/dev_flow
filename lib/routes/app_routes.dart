import 'package:get/get.dart';
import '../presentation/bindings/onboarding/login/login_binding.dart';
import '../presentation/bindings/onboarding/onboarding_binding.dart';
import '../presentation/views/auth/signup/signup.dart';
import '../presentation/views/onboarding/onboarding.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  static final routes = [
    GetPage(
      name: onboarding,
      page: () => const Onboarding(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: login,
      page: () => const Login(),
      binding: LoginBinding(),
    ),
  ];
}
