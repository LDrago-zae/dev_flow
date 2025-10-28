import 'package:get/get.dart';
import '../presentation/bindings/onboarding/login/login_binding.dart';
import '../presentation/bindings/onboarding/onboarding_binding.dart';
import '../presentation/views/auth/otp/verification_screen.dart';
import '../presentation/views/auth/signup/signup.dart';
import '../presentation/views/onboarding/onboarding.dart';
import '../presentation/views/splash/splash.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String verificationScreen = '/verification-screen';
  static const String signup = '/signup';
  static const String splash = '/splash';

  static final routes = [
    GetPage(
      name: onboarding,
      page: () => const Onboarding(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: login,
      page: () => const Signup(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: verificationScreen,
      page: () => const VerificationScreen(),
    ),
    GetPage(
      name: splash,
      page: () => const Splash(),
    ),
  ];
}
