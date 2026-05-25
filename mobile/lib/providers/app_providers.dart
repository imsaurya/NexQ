import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/firebase/firebase_auth_config.dart';
import '../core/firebase/firebase_providers.dart';
import '../repositories/category_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/shop_repository.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../services/queue_engine_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  const webClientId = FirebaseAuthConfig.googleWebClientId;

  if (kIsWeb) {
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      clientId: webClientId,
    );
  }

  return GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: webClientId,
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(firestore: ref.watch(firestoreProvider));
});

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(firestore: ref.watch(firestoreProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(firestore: ref.watch(firestoreProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(firestore: ref.watch(firestoreProvider));
});

final queueEngineProvider = Provider<QueueEngineService>((ref) {
  return QueueEngineService(
    firestore: ref.watch(firestoreProvider),
    notificationRepository: ref.watch(notificationRepositoryProvider),
  );
});
