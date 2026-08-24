enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? role; // 'ADMIN', 'WORKER', etc.
  final String? username;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.role,
    this.username,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? role,
    String? username,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      role: role ?? this.role,
      username: username ?? this.username,
    );
  }
}
