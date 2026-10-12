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
        // Centralized here, not per-screen: ANY 401 from ANY call means the stored token is
        // stale or invalid, so clear it and let the caller (dioProvider, which has access to
        // Riverpod's ref) re-evaluate auth state — every screen gets this behavior for free
        // without remembering to handle it individually.
        if (error.response?.statusCode == 401) {
          await authStorage.clearToken();
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
