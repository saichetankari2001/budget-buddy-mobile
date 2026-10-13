import 'package:dio/dio.dart';
import 'auth_storage.dart';

const String kApiBaseUrl = 'https://budget-buddy-1aur.vercel.app';

/// Builds the one [Dio] instance every feature screen's API calls should go
/// through. Two concerns are centralized here so no caller has to repeat
/// them:
///  1. Every outgoing request gets `Authorization: Bearer <token>` attached
///     automatically from [AuthStorage], if a token is stored.
///  2. Any `401` response from any call means the stored token is stale or
///     invalid: it's cleared here and [onUnauthorized] is invoked so the
///     caller (which holds the Riverpod `ref`/router) can route back to
///     login. Individual feature screens never need to special-case 401.
Dio createApiClient(AuthStorage authStorage, {void Function()? onUnauthorized}) {
  final dio = Dio(BaseOptions(baseUrl: kApiBaseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await authStorage.readToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Centralized here, not per-screen: a 401 from any call OTHER than the auth endpoints
        // themselves means the stored token is stale or invalid, so clear it and let the caller
        // (dioProvider, which has access to Riverpod's ref) re-evaluate auth state — every screen
        // gets this behavior for free without remembering to handle it individually. A 401 from
        // /api/auth/login or /api/auth/signup itself means wrong credentials or a validation
        // failure, not an expired session — treating it the same way would invalidate
        // authStateProvider and race with login()'s own catch block, overwriting the real error
        // with a fresh AsyncData before LoginScreen could render it.
        final isAuthEndpoint = error.requestOptions.path.startsWith('/api/auth/');
        if (error.response?.statusCode == 401 && !isAuthEndpoint) {
          await authStorage.clearToken();
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
