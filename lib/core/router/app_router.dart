import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/main/presentation/main_shell.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final authState = ref.read(authStatusProvider);
      if (authState.isLoading) return null;

      final isAuthenticated = authState.valueOrNull == AuthStatus.authenticated;
      final location = state.matchedLocation;

      if (!isAuthenticated) {
        return location == '/login' ? null : '/login';
      }

      if (location == '/login' || location == '/') {
        final done = await ref.read(onboardingDoneProvider.future);
        return done ? '/home' : '/onboarding';
      }

      return null;
    },
    refreshListenable: _AuthListenable(ref),
    routes: [
      GoRoute(path: '/login',      builder: (ctx, s) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (ctx, s) => const OnboardingScreen()),
      GoRoute(path: '/home',       builder: (ctx, s) => const MainShell()),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authStatusProvider, (prev, next) => notifyListeners());
  }
}
