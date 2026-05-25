import 'package:flutter/foundation.dart';

/// Debug logging for auth, profile, router, and Firestore (debug builds only).
class AuthDebug {
  AuthDebug._();

  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[NexQ Auth] $message');
    }
  }

  static void authState(String message) => log('authState: $message');

  static void profile(String message) => log('profile: $message');

  static void router(String message) => log('router: $message');

  static void firestore(String message) => log('firestore: $message');
}
