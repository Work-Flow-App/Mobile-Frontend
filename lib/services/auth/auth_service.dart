import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/auth/auth_model.dart';
import 'package:mobile_frontend/services/network/dio_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(dioProvider));
});

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'userName': username, 'password': password},
      );

      // --- FIX 1: Ensure data is a Map ---
      final data = response.data;

      // If Dio returns a String (sometimes happens), decode it manually
      final Map<String, dynamic> jsonData = (data is String)
          ? jsonDecode(data)
          : data;

      return AuthResponse.fromJson(jsonData);
    } on DioException catch (e) {
      // --- FIX 2: Safely handle Error Responses ---
      String errorMessage = 'Login failed. Please try again.';

      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;

        // If errorData is a Map (standard JSON error), get 'message'
        if (errorData is Map<String, dynamic>) {
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        }
        // If errorData is just a String (plain text error from server)
        else if (errorData is String) {
          errorMessage = errorData;
        }
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("An unexpected error occurred: $e");
    }
  }

  // Keep signup as mock or implement similarly if you have the endpoint
  Future<AuthResponse> signup(
    String username,
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    return AuthResponse(
      accessToken: "mock_access_token_signup",
      refreshToken: "mock_refresh_token_signup",
      tokenType: "Bearer",
      expiresIn: 3600,
      errorMessage: "",
    );
  }
}
