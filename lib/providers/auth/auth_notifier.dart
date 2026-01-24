import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/auth/auth_state.dart';
import 'package:mobile_frontend/services/auth/auth_service.dart';
import 'package:mobile_frontend/services/storage/storage_service.dart';

// FIX: Explicitly add 'StateNotifierProvider<AuthNotifier, AuthState>' before the variable name
final StateNotifierProvider<AuthNotifier, AuthState> authNotifierProvider = 
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(storageServiceProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final StorageService _storage;

  AuthNotifier(this._authService, this._storage) : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _storage.getAccessToken();
    final role = await _storage.getUserRole();

    if (token != null && token.isNotEmpty) {
      state = state.copyWith(status: AuthStatus.authenticated, role: role);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _authService.login(username, password);

      String role = username.toLowerCase().contains('admin')
          ? 'ADMIN'
          : 'WORKER';

      await _storage.saveAuthData(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        role: role,
      );

      state = state.copyWith(status: AuthStatus.authenticated, role: role);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signup(
    String username,
    String email,
    String password,
    String role,
  ) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _authService.signup(username, email, password);

      await _storage.saveAuthData(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        role: role,
      );

      state = state.copyWith(status: AuthStatus.authenticated, role: role);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    state = state.copyWith(status: AuthStatus.unauthenticated, role: null);
  }
}