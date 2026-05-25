import 'simple_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/user_roles.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/auth_debug.dart';
import '../models/app_user.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import 'app_providers.dart';

/// Firebase Auth user from [FirebaseAuth.authStateChanges].
final authStateProvider = StreamProvider<User?>((ref) {
  AuthDebug.authState('subscribing authStateChanges');
  return ref.watch(authServiceProvider).authStateChanges.distinct(
        (a, b) => a?.uid == b?.uid,
      );
});

/// Synchronous Firebase Auth user (null when logged out).
final firebaseAuthUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Firestore profile for the signed-in Firebase user.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authAsync = ref.watch(authStateProvider);

  if (authAsync.isLoading) {
    return const Stream<AppUser?>.empty();
  }

  final uid = authAsync.valueOrNull?.uid;
  if (uid == null) {
    return Stream.value(null);
  }

  return ref.watch(userRepositoryProvider).watchUser(uid);
});

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  AuthService get _auth => _ref.read(authServiceProvider);
  UserRepository get _users => _ref.read(userRepositoryProvider);

  Future<AppUser> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await _auth.signInWithEmail(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException('Sign-in succeeded but session is missing.');
      }
      return _ensureProfile(user);
    });
    if (state.hasError) throw state.error!;
    return state.requireValue!;
  }

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.customer,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await _auth.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException('Account created but user session is missing.');
      }
      return _users.ensureUserProfile(
        userId: user.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        photoUrl: user.photoURL,
        role: role,
      );
    });
    if (state.hasError) throw state.error!;
    return state.requireValue!;
  }

  Future<AppUser> signInWithGoogle({UserRole role = UserRole.customer}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await _auth.signInWithGoogle();
      final user = credential.user;
      if (user == null) {
        throw const AppException('Google sign-in failed: no user returned.');
      }
      final existing = await _users.getUser(user.uid);
      return _users.ensureUserProfile(
        userId: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL,
        role: existing?.role ?? role,
      );
    });
    if (state.hasError) throw state.error!;
    return state.requireValue!;
  }

  Future<void> signOut() async {
  await _auth.signOut();
  _ref.read(currentProfileProvider.notifier).clearProfile();
}

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email);
  }

  Future<AppUser> _ensureProfile(User user) async {
    final existing = await _users.getUser(user.uid);
    return _users.ensureUserProfile(
      userId: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'User',
      photoUrl: user.photoURL,
      role: existing?.role ?? UserRole.customer,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AppUser?>>((ref) {
  return AuthController(ref);
});

/// Home route for a role (used after login/register).
String homeRouteForRole(UserRole role) {
  return switch (role) {
    UserRole.shopOwner => '/owner',
    UserRole.admin => '/customer',
    UserRole.customer => '/customer',
  };
}
