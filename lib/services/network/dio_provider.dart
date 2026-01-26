import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Import this to decode the new token
import 'package:mobile_frontend/services/storage/storage_service.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.dev.workfloow.app/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final storage = ref.read(storageServiceProvider);

  // 1. ADD LOGGING INTERCEPTOR (Before the auth interceptor)
  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      // 2. Intercept Request: Add Token
      onRequest: (options, handler) async {
        // We don't want to add the token if we are calling login or refresh endpoints
        if (!options.path.contains('/auth/login') &&
            !options.path.contains('/auth/refresh')) {
          final token = await storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },

      // 3. Intercept Error: Handle 401 & Refresh
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          // Check if we already tried to refresh
          if (error.requestOptions.extra['retry'] == true) {
            // Refresh failed or we already retried, force logout
            ref.read(authNotifierProvider.notifier).logout();
            return handler.reject(error);
          }

          final refreshToken = await storage.getRefreshToken();

          if (refreshToken != null) {
            try {
              // LOCK: Create a new Dio instance to avoid circular loops
              // We pass the same options (base URL) but NO interceptors to avoid infinite loops
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: dio.options.baseUrl,
                  headers: {'Content-Type': 'application/json'},
                ),
              );

              // Call Refresh Endpoint
              final refreshResponse = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );

              final newAccessToken = refreshResponse.data['accessToken'];
              final newRefreshToken = refreshResponse.data['refreshToken'];

              // CRITICAL IMPROVEMENT: Decode the new token to ensure we have the latest role
              Map<String, dynamic> decodedToken = JwtDecoder.decode(
                newAccessToken,
              );
              String rawRole = decodedToken['role'] ?? 'WORKER';
              String normalizedRole = rawRole.replaceFirst('ROLE_', '');

              // Update Storage with NEW Access Token, NEW Refresh Token, and UPDATED Role
              await storage.saveAuthData(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
                role: normalizedRole,
              );

              // Retry original request with new token
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';
              error.requestOptions.extra['retry'] = true;

              final clonedRequest = await dio.fetch(error.requestOptions);
              return handler.resolve(clonedRequest);
            } catch (e) {
              // Refresh failed completely (e.g., refresh token expired)
              ref.read(authNotifierProvider.notifier).logout();
              return handler.reject(error);
            }
          }
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});
