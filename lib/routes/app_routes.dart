import 'package:go_router/go_router.dart';
import '../presentation/bindings/onboarding/login/login_binding.dart';
import '../presentation/bindings/onboarding/onboarding_binding.dart';
import '../presentation/views/auth/otp/otp_verification.dart';
import '../presentation/views/auth/otp/verification_screen.dart';
import '../presentation/views/auth/signin/signin.dart';
import '../presentation/views/auth/signin/signin_verification.dart';
import '../presentation/views/auth/signup/signup.dart';
import '../presentation/views/get_started/get_started.dart';
import '../presentation/views/home/home_screen.dart';
import '../presentation/views/onboarding/onboarding.dart';
import '../presentation/views/profile/profile.dart';
import '../presentation/views/splash/splash.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String verificationScreen = '/verification-screen';
  static const String signup = '/signup';
  static const String signin = '/signin';
  static const String otpVerification = '/otp-verification';
  static const String signinVerification = '/signin-verification';
  static const String getStarted = '/get-started';
  static const String profile = '/profile';
  static const String splash = '/splash';
  static const String home = '/home';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash, builder: (context, state) => const Splash()),
      GoRoute(
        path: onboarding,
        builder: (context, state) {
          // Initialize binding
          OnboardingBinding().dependencies();
          return const Onboarding();
        },
      ),
      GoRoute(
        path: getStarted,
        builder: (context, state) => const GetStarted(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) {
          // Initialize binding
          LoginBinding().dependencies();
          return const Signup();
        },
      ),
      GoRoute(path: signup, builder: (context, state) => const Signup()),
      GoRoute(path: signin, builder: (context, state) => const SignIn()),
      GoRoute(
        path: otpVerification,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpVerification(email: email);
        },
      ),
      GoRoute(
        path: verificationScreen,
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: signinVerification,
        builder: (context, state) => const SigninVerification(),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(path: home, builder: (context, state) => const HomeScreen()),
    ],
  );
}
