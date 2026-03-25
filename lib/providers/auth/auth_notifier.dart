import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mobile_frontend/models/auth/auth_state.dart';
import 'package:mobile_frontend/services/auth/auth_service.dart';
import 'package:mobile_frontend/services/storage/storage_service.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';

// Explicit type definition to prevent circularity error
final StateNotifierProvider<AuthNotifier, AuthState> authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
      return AuthNotifier(
        ref,
        ref.read(authServiceProvider),
        ref.read(storageServiceProvider),
      );
    });

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final AuthService _authService;
  final StorageService _storage;

  AuthNotifier(this.ref, this._authService, this._storage)
    : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _storage.getAccessToken();
    final role = await _storage.getUserRole();

    if (token != null && token.isNotEmpty) {
      // Optional: Check if token is expired client-side
      if (JwtDecoder.isExpired(token)) {
        await logout();
        return;
      }
      state = state.copyWith(status: AuthStatus.authenticated, role: role);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      // 1. Call API
      final response = await _authService.login(username, password);

      // 2. Decode Token to get Role
      // The API returns "ROLE_WORKER" or "ROLE_ADMIN" inside the token
      Map<String, dynamic> decodedToken = JwtDecoder.decode(
        response.accessToken,
      );

      String rawRole = decodedToken['role'] ?? 'WORKER';

      // 3. Normalize Role (Remove 'ROLE_' prefix to match your app logic)
      // "ROLE_WORKER" -> "WORKER"
      // "ROLE_ADMIN"  -> "ADMIN"
      String normalizedRole = rawRole.replaceFirst('ROLE_', '');

      // 4. Save to Secure Storage
      await _storage.saveAuthData(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        role: normalizedRole,
      );

      _clearJobCache();

      // 5. Update UI State
      state = state.copyWith(
        status: AuthStatus.authenticated,
        role: normalizedRole,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
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

      _clearJobCache();

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

    _clearJobCache();

    state = state.copyWith(status: AuthStatus.unauthenticated, role: null);
  }

  void _clearJobCache() {
    ref.invalidate(assignedStepsFutureProvider);
    ref.invalidate(stepTimelineProvider);
    ref.invalidate(stepWorkLogsProvider);
    ref.invalidate(filteredStepsProvider);
    ref.invalidate(selectedStepIdProvider);
  }
}
