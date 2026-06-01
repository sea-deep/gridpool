// ignore_for_file: prefer_initializing_formals
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: firebase_auth.FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    googleSignIn: google_sign_in.GoogleSignIn(),
  );
});

class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  // ignore: unused_field
  final FirebaseFirestore _firestore; // Kept to avoid breaking the provider parameter
  final google_sign_in.GoogleSignIn _googleSignIn;

  String get _baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';
  }

  AuthRepository({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required google_sign_in.GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  /// Syncs the Firebase user to the MongoDB backend via POST /users/sync.
  /// Returns the HTTP response.
  Future<http.Response> _syncUserToBackend(firebase_auth.User firebaseUser) async {
    final token = await firebaseUser.getIdToken();
    final syncUrl = Uri.parse('$_baseUrl/users/sync');
    final response = await http.post(
      syncUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': firebaseUser.displayName ?? 'Unknown',
        'email': firebaseUser.email ?? '',
        'avatarUrl': firebaseUser.photoURL ?? '',
      }),
    );
    if (kDebugMode) {
      debugPrint('_syncUserToBackend completed with status: ${response.statusCode}');
    }
    return response;
  }

  Future<User?> _mapFirebaseUser(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      return null;
    }

    try {
      final token = await firebaseUser.getIdToken();
      final targetUrl = Uri.parse('$_baseUrl/users/profile');
      var response = await http.get(
        targetUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('User profile not found in MongoDB, triggering auto-sync');
        }
        response = await _syncUserToBackend(firebaseUser);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('User profile fetched successfully');
        }
        return User(
          id: firebaseUser.uid,
          name: data['name'] ?? firebaseUser.displayName ?? 'Unknown',
          email: data['email'] ?? firebaseUser.email ?? '',
          avatarUrl: data['avatarUrl'] ?? firebaseUser.photoURL ?? '',
          upiId: data['upiId'] as String?,
          notificationPreference: data['notificationPreference'] as bool? ?? true,
        );
      } else {
        if (kDebugMode) {
          debugPrint('_mapFirebaseUser received non-200 response');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('_mapFirebaseUser error reading user document: $e');
      }
    }

    return User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Unknown User',
      email: firebaseUser.email ?? '',
      avatarUrl: firebaseUser.photoURL ?? '',
      upiId: null,
    );
  }

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap(_mapFirebaseUser);
  }

  /// Checks whether the user has completed the onboarding flow.
  Future<bool> isOnboardingCompleted(String userId) async {
    if (kDebugMode) {
      debugPrint('Checking onboarding status');
    }
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }
      final token = await user.getIdToken();
      final targetUrl = Uri.parse('$_baseUrl/users/profile');
      var response = await http.get(
        targetUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('User not found in MongoDB, triggering auto-sync');
        }
        response = await _syncUserToBackend(user);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final completed = data['onboardingCompleted'] ?? false;
        if (kDebugMode) {
          debugPrint('Onboarding status check completed');
        }
        return completed;
      } else {
        if (kDebugMode) {
          debugPrint('isOnboardingCompleted received non-200 response');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('isOnboardingCompleted failed: $e');
      }
      rethrow;
    }
  }

  /// Marks the user's onboarding as completed in MongoDB, updating fields.
  Future<User> completeOnboarding({
    required String userId,
    required String name,
    required String? upiId,
    required bool notificationPreference,
  }) async {
    if (kDebugMode) {
      debugPrint('Starting onboarding completion');
    }
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }
      final token = await user.getIdToken();
      final targetUrl = Uri.parse('$_baseUrl/users/onboarding/complete');
      final response = await http.post(
        targetUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name.trim(),
          'upiId': upiId?.trim().isEmpty ?? true ? null : upiId?.trim(),
          'notificationPreference': notificationPreference,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to complete onboarding');
      }
      if (kDebugMode) {
        debugPrint('Onboarding completed successfully');
      }
      final data = jsonDecode(response.body);
      return User(
        id: user.uid,
        name: data['name'] ?? name,
        email: data['email'] ?? user.email ?? '',
        avatarUrl: data['avatarUrl'] ?? user.photoURL ?? '',
        upiId: data['upiId'] as String?,
        notificationPreference: data['notificationPreference'] as bool? ?? true,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('completeOnboarding failed: $e');
      }
      rethrow;
    }
  }

  Future<User> signInWithGoogle() async {
    if (kDebugMode) {
      debugPrint('Google sign-in initiated');
    }
    final google_sign_in.GoogleSignInAccount? googleUser = await _googleSignIn
        .signIn();
    if (googleUser == null) {
      throw Exception('Sign in aborted by user');
    }

    final google_sign_in.GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw Exception('Failed to log in with Google');
    }

    if (kDebugMode) {
      debugPrint('Google sign-in successful, syncing user to backend');
    }

    final mappedUser = User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Unknown User',
      email: firebaseUser.email ?? '',
      avatarUrl: firebaseUser.photoURL ?? '',
    );

    final response = await _syncUserToBackend(firebaseUser);

    if (response.statusCode != 200) {
      throw Exception('Failed to sync user with database');
    }

    if (kDebugMode) {
      debugPrint('User sync successful');
    }
    final data = jsonDecode(response.body);
    return User(
      id: firebaseUser.uid,
      name: data['name'] ?? mappedUser.name,
      email: data['email'] ?? mappedUser.email,
      avatarUrl: data['avatarUrl'] ?? mappedUser.avatarUrl,
      upiId: data['upiId'] as String?,
      notificationPreference: data['notificationPreference'] as bool? ?? true,
    );
  }

  Future<void> updateUpiId(String userId, String? upiId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }
      final token = await user.getIdToken();
      final targetUrl = Uri.parse('$_baseUrl/users/profile');
      final response = await http.post(
        targetUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'upiId': upiId?.trim().isEmpty ?? true ? null : upiId?.trim(),
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update UPI ID');
      }
      if (kDebugMode) {
        debugPrint('UPI ID updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('updateUpiId failed: $e');
      }
      rethrow;
    }
  }

  Future<User> updateProfile({
    required String name,
    required String? upiId,
    required bool notificationPreference,
    String? avatarUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final token = await user.getIdToken();
      final targetUrl = Uri.parse('$_baseUrl/users/profile');

      final body = <String, dynamic>{
        'name': name.trim(),
        'upiId': upiId?.trim().isEmpty ?? true ? null : upiId?.trim(),
        'notificationPreference': notificationPreference,
      };
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        body['avatarUrl'] = avatarUrl;
      }

      final response = await http.post(
        targetUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update profile');
      }
      final data = jsonDecode(response.body);
      return User(
        id: user.uid,
        name: data['name'] ?? name,
        email: data['email'] ?? user.email ?? '',
        avatarUrl: data['avatarUrl'] ?? user.photoURL ?? '',
        upiId: data['upiId'] as String?,
        notificationPreference: data['notificationPreference'] as bool? ?? true,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('updateProfile failed: $e');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (kDebugMode) {
      debugPrint('Signing out');
    }
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
