import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Single entry point for Firebase initialization (avoids duplicate-app errors).
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool get isInitialized => Firebase.apps.isNotEmpty;

  static Future<void> initialize() async {
    if (isInitialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await initialize();
  }

  static Future<FirebaseFirestore> get firestoreInstance async {
    return FirebaseFirestore.instance;
  }
}
