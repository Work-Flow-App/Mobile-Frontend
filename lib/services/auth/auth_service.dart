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
    // REAL API CALL:
    // final response = await _dio.post('/auth/login', data: {'username': username, 'password': password});
    // return AuthResponse.fromJson(response.data);

    // MOCK SIMULATION:
    await Future.delayed(const Duration(seconds: 1));
    if (username == 'fail') throw Exception("Invalid credentials");

    return AuthResponse(
      accessToken: "mock_access_token_123",
      refreshToken: "mock_refresh_token_456",
      tokenType: "Bearer",
      expiresIn: 3600,
      errorMessage: "",
    );
  }

  Future<AuthResponse> signup(String username, String email, String password) async {
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