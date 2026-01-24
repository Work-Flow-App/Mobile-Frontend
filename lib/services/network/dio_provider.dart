import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/services/storage/storage_service.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.yourdomain.com/v1', // Replace with real API
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  final storage = ref.read(storageServiceProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      // 1. Intercept Request: Add Token
      onRequest: (options, handler) async {
        final token = await storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },

      // 2. Intercept Error: Handle 401 & Refresh
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          // Check if we already tried to refresh
          if (error.requestOptions.extra['retry'] == true) {
             // Refresh failed, force logout
             ref.read(authNotifierProvider.notifier).logout();
             return handler.reject(error);
          }

          final refreshToken = await storage.getRefreshToken();
          if (refreshToken != null) {
            try {
              // LOCK: Create a new Dio instance to avoid circular loops
              final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
              
              // Call Refresh Endpoint
              final refreshResponse = await refreshDio.post('/auth/refresh', data: {
                'refreshToken': refreshToken,
              });

              final newAccessToken = refreshResponse.data['accessToken'];
              final newRefreshToken = refreshResponse.data['refreshToken'];

              // Update Storage
              // Note: You need to know the role here, or keep the existing one
              final role = await storage.getUserRole() ?? 'WORKER'; 
              await storage.saveAuthData(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
                role: role,
              );

              // Retry original request with new token
              error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              error.requestOptions.extra['retry'] = true;
              
              final clonedRequest = await dio.fetch(error.requestOptions);
              return handler.resolve(clonedRequest);

            } catch (e) {
              // Refresh failed completely
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