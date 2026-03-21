import 'package:cursor_hack/features/auth/presentation/login_screen.dart';
import 'package:cursor_hack/features/home/presentation/home_screen.dart';
import 'package:cursor_hack/features/onboarding/presentation/onboarding_screen.dart';
import 'package:cursor_hack/router/app_route_constant.dart';
import 'package:cursor_hack/services/storage/storage_service.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final Set<String> _authRoutes = <String>{
    AppRouteConstant.onboarding,
    AppRouteConstant.login,
  };

  static final GoRouter router = GoRouter(
    initialLocation: AppRouteConstant.onboarding,
    redirect: (context, state) async {
      final String? token = await StorageService.instance.getToken();
      final bool loggedIn = token != null && token.isNotEmpty;
      final bool onAuthPage = _authRoutes.contains(state.matchedLocation);

      if (loggedIn && onAuthPage) return AppRouteConstant.home;
      if (!loggedIn && !onAuthPage) return AppRouteConstant.onboarding;
      return null;
    },
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
      GoRoute(
        name: AppRouteConstant.home,
        path: AppRouteConstant.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
