enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? role; // 'ADMIN', 'WORKER', etc.

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.role,
  });

  AuthState copyWith({AuthStatus? status, String? errorMessage, String? role}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      role: role ?? this.role,
    );
  }
}
