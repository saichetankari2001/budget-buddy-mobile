import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

final dioProvider = Provider<Dio>((ref) {
  return createApiClient(
    ref.watch(authStorageProvider),
    // The token is already cleared inside createApiClient's own onError hook (Task 7) — this
    // callback's only job is telling Riverpod the auth state is now stale, so _RootGate (Task 11)
    // re-reads AuthStorage and swaps to the login screen on its own, from wherever the user was.
    onUnauthorized: () => ref.invalidate(authStateProvider),
  );
});

class AuthResult {
  const AuthResult({required this.isAuthenticated});
  final bool isAuthenticated;
}

class AuthStateNotifier extends AsyncNotifier<AuthResult> {
  @override
  Future<AuthResult> build() async {
    final token = await ref.watch(authStorageProvider).readToken();
    return AuthResult(isAuthenticated: token != null);
  }

  Future<void> login(String email, String password) async {
    // copyWithPrevious keeps isReloading true during this transition — _RootGate's
    // skipLoadingOnReload (main.dart) relies on that flag to keep showing the current screen
    // instead of flashing the full-screen spinner over it.
    state = const AsyncLoading<AuthResult>().copyWithPrevious(state);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/api/auth/login', data: {'email': email, 'password': password});
      final token = response.data['token'] as String;
      await ref.read(authStorageProvider).saveToken(token);
      state = const AsyncData(AuthResult(isAuthenticated: true));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> signup(String email, String password) async {
    state = const AsyncLoading<AuthResult>().copyWithPrevious(state);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/api/auth/signup', data: {'email': email, 'password': password});
      final token = response.data['token'] as String;
      await ref.read(authStorageProvider).saveToken(token);
      state = const AsyncData(AuthResult(isAuthenticated: true));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await ref.read(authStorageProvider).clearToken();
    state = const AsyncData(AuthResult(isAuthenticated: false));
  }
}

final authStateProvider = AsyncNotifierProvider<AuthStateNotifier, AuthResult>(AuthStateNotifier.new);
