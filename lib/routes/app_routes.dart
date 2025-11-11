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
import '../presentation/views/activity/activity_screen.dart';
import '../presentation/views/reports/reports_screen.dart';
import '../presentation/views/news/news_screen.dart';
import '../presentation/views/news/news_detail_screen.dart';
import '../presentation/widgets/app_shell_scaffold.dart';
import '../data/models/news_model.dart';

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
  static const String activity = '/activity';
  static const String reports = '/reports';
  static const String news = '/news';
  static const String projectDetails = '/project-details';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      // Routes without bottom navigation
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

      // Shell route with bottom navigation for main screens
      ShellRoute(
        builder: (context, state, child) {
          // Determine selected index based on current route
          int selectedIndex = 0;
          final location = state.uri.path;
          if (location.startsWith('/home')) {
            selectedIndex = 0;
          } else if (location.startsWith('/activity')) {
            selectedIndex = 1;
          } else if (location.startsWith('/reports')) {
            selectedIndex = 2;
          } else if (location.startsWith('/news')) {
            selectedIndex = 3;
          } else if (location.startsWith('/profile')) {
            selectedIndex = 4;
          }

          return AppShellScaffold(selectedIndex: selectedIndex, child: child);
        },
        routes: [
          GoRoute(path: home, builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: activity,
            builder: (context, state) => const ActivityScreen(),
          ),
          GoRoute(
            path: reports,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: news,
            builder: (context, state) => const NewsScreen(),
          ),
          GoRoute(
            path: '$news/:url',
            builder: (context, state) {
              final article = state.extra as NewsArticle?;
              if (article != null) {
                return NewsDetailScreen(article: article);
              }
              // Fallback if article not passed
              return const NewsScreen();
            },
          ),
          GoRoute(
            path: profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
