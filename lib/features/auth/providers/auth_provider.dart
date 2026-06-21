import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

final authStatusProvider = AsyncNotifierProvider<AuthNotifier, AuthStatus>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<AuthStatus> {
  @override
  Future<AuthStatus> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final loggedIn = await repo.isLoggedIn();
    return loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).loginWithGoogle();
      return AuthStatus.authenticated;
    });
  }

  Future<void> loginWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).loginWithApple();
      return AuthStatus.authenticated;
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(AuthStatus.unauthenticated);
  }
}
