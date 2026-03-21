import 'package:cursor_hack/features/auth/presentation/login_screen.dart';
import 'package:cursor_hack/features/onboarding/presentation/onboarding_screen.dart';
import 'package:cursor_hack/router/app_route_constant.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRouteConstant.onboarding,
    routes: <RouteBase>[
      GoRoute(
        name: AppRouteConstant.onboarding,
        path: AppRouteConstant.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        name: AppRouteConstant.login,
        path: AppRouteConstant.login,
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
}
