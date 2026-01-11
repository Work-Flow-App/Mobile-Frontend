import 'package:mobile_frontend/models/auth/auth_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';

  Future<AuthResponse> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    final dummyResponse = {
      "accessToken": "dummy_access",
      "refreshToken": "dummy_refresh",
      "tokenType": "Bearer",
      "expiresIn": 3600,
      "errorMessage": "",
    };

    await saveTokens(
      dummyResponse['accessToken'] as String,
      dummyResponse['refreshToken'] as String,
    );

    return AuthResponse.fromJson(dummyResponse);
  }

  Future<AuthResponse> signup(
    String username,
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    final dummyResponse = {
      "accessToken": "dummy_access_signup",
      "refreshToken": "dummy_refresh_signup",
      "tokenType": "Bearer",
      "expiresIn": 3600,
      "errorMessage": "",
    };

    await saveTokens(
      dummyResponse['accessToken'] as String,
      dummyResponse['refreshToken'] as String,
    );

    return AuthResponse.fromJson(dummyResponse);
  }

  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
