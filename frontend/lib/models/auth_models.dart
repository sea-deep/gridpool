class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String? upiId;
  final bool notificationPreference;

  static const _sentinel = Object();

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.upiId,
    this.notificationPreference = true,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    Object? upiId = _sentinel,
    bool? onboardingCompleted,
    bool? notificationPreference,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      upiId: identical(upiId, _sentinel) ? this.upiId : upiId as String?,
      notificationPreference: notificationPreference ?? this.notificationPreference,
    );
  }
}

enum AuthStatus { initial, loading, unauthenticated, onboarding, authenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  static const _sentinel = Object();

  const AuthState({required this.status, this.user, this.error});

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.onboarding() =>
      const AuthState(status: AuthStatus.onboarding);
  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  AuthState copyWith({AuthStatus? status, User? user, Object? error = _sentinel}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}
