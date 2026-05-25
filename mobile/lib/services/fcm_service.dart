import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../repositories/user_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(
    messaging: FirebaseMessaging.instance,
    userRepository: ref.watch(userRepositoryProvider),
  );
});

class FcmService {
  FcmService({
    required FirebaseMessaging messaging,
    required UserRepository userRepository,
  })  : _messaging = messaging,
        _userRepository = userRepository;

  final FirebaseMessaging _messaging;
  final UserRepository _userRepository;
  bool _initialized = false;

  Future<void> initialize(String userId) async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    await _requestPermission();

    final token = await _messaging.getToken();
    if (token != null) {
      await _userRepository.updateFcmToken(userId, token);
    }

    _messaging.onTokenRefresh.listen((token) {
      _userRepository.updateFcmToken(userId, token);
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'Foreground message: ${message.notification?.title}',
      );
    });

    _initialized = true;
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}