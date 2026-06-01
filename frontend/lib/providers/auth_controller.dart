import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/services/auth_repository.dart';
import 'package:frontend/models/auth_models.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  StreamSubscription<User?>? _authSubscription;

  @override
  AuthState build() {
    // Start listening to the auth state stream
    _authSubscription?.cancel();
    _authSubscription = _repository.authStateChanges().listen((user) async {
      if (user == null) {
        state = AuthState.unauthenticated();
      } else {
        // Check if user needs onboarding
        try {
          if (kDebugMode) {
            debugPrint('AuthController: Checking onboarding status');
          }
          final onboardingCompleted = await _repository.isOnboardingCompleted(
            user.id,
          );

          if (!onboardingCompleted) {
            if (kDebugMode) {
              debugPrint('AuthController: User needs onboarding');
            }
            state = AuthState.onboarding().copyWith(user: user);
          } else {
            if (kDebugMode) {
              debugPrint('AuthController: User authenticated');
            }
            state = AuthState.authenticated(user);
          }
        } catch (e) {
          // Network error — allow access but log warning. User might need to retry onboarding check.
          if (kDebugMode) {
            debugPrint('Warning: Could not verify onboarding status: $e');
          }
          state = AuthState.authenticated(user);
        }
      }
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    return AuthState.initial();
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.signInWithGoogle();
      // The stream listener will pick up the user and update the state
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.signOut();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> completeOnboarding({
    required String name,
    required String? upiId,
    required bool notificationPreference,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      if (state.user != null) {
        final updatedUser = await _repository.completeOnboarding(
          userId: state.user!.id,
          name: name,
          upiId: upiId,
          notificationPreference: notificationPreference,
        );
        state = AuthState.authenticated(updatedUser);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.onboarding,
        error: e.toString(),
      );
    }
  }

  Future<void> updateProfile({
    required String name,
    required String? upiId,
    required bool notificationPreference,
    String? avatarUrl,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    final previousState = state;
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final updatedUser = await _repository.updateProfile(
        name: name,
        upiId: upiId,
        notificationPreference: notificationPreference,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: updatedUser,
      );
    } catch (e) {
      state = previousState.copyWith(error: e.toString());
      if (kDebugMode) {
        debugPrint('AuthController.updateProfile failed: $e');
      }
      rethrow;
    }
  }

  Future<void> updateUpiId(String upiId) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    final previousState = state;
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.updateUpiId(currentUser.id, upiId);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: currentUser.copyWith(upiId: upiId.trim()),
      );
    } catch (e) {
      state = previousState.copyWith(error: e.toString());
      if (kDebugMode) {
        debugPrint('AuthController.updateUpiId failed: $e');
      }
      rethrow;
    }
  }
}
