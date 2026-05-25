import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'models/app_user.dart';
import 'providers/app_providers.dart';
import 'providers/simple_auth.dart';
import 'routes/simple_router.dart';
import 'services/fcm_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();

  final prefs = await SharedPreferences.getInstance();

  final firebaseUser = await FirebaseAuth.instance
      .authStateChanges()
      .first
      .timeout(const Duration(seconds: 5), onTimeout: () => null);

  AppUser? initialProfile;
  if (firebaseUser != null) {
    try {
      final fs = await FirebaseBootstrap.firestoreInstance;
      final doc = await fs
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists) {
        initialProfile = AppUser.fromFirestore(doc);
      }
    } catch (_) {
      // Ignore — user will be asked to log in again
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialFirebaseUserProvider.overrideWithValue(firebaseUser),
        initialProfileProvider.overrideWithValue(initialProfile),
      ],
      child: const NexQApp(),
    ),
  );
}

class NexQApp extends ConsumerWidget {
  const NexQApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(simpleRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    ref.watch(authWatcherProvider);

    ref.listen(currentProfileProvider, (previous, next) {
      if (next != null) {
        ref.read(fcmServiceProvider).initialize(next.id);
      }
    });

    return MaterialApp.router(
      title: 'NexQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
