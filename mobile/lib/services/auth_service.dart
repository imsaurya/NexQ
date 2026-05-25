import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/user_roles.dart';
import '../core/errors/app_exception.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _auth = firebaseAuth,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e), code: e.code);
    } catch (e) {
      throw AppException(_wrapUnknown(e));
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.customer,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(displayName.trim());
        await user.reload();
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e), code: e.code);
    } catch (e) {
      throw AppException(_wrapUnknown(e));
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AppException('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw const AppException(
          'Google Sign-In failed: missing ID token. Add SHA-1 in Firebase Console, '
          're-download google-services.json, and verify FirebaseAuthConfig.googleWebClientId.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e), code: e.code);
    } on PlatformException catch (e) {
      throw AppException(
        e.message ?? 'Google sign-in failed (${e.code}).',
        code: e.code,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(_wrapUnknown(e));
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AppException(_wrapUnknown(e));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e), code: e.code);
    }
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException('Not authenticated');
    }
    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }
    await user.reload();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account found with this email or password is incorrect.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Console.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }

  String _wrapUnknown(Object e) {
    if (kDebugMode) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}

extension AuthUserMapper on User {
  AppUser toPartialAppUser({UserRole role = UserRole.customer}) {
    return AppUser(
      id: uid,
      email: email ?? '',
      displayName: displayName ?? 'User',
      photoUrl: photoURL,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
