import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/user_roles.dart';
import '../models/app_user.dart';
import 'app_providers.dart';

final initialFirebaseUserProvider = Provider<User?>((ref) => null);
final initialProfileProvider = Provider<AppUser?>((ref) => null);

final currentProfileProvider =
    StateNotifierProvider<CurrentProfileNotifier, AppUser?>(
  (ref) => CurrentProfileNotifier(
    ref.read(initialProfileProvider),
  ),
);

class CurrentProfileNotifier extends StateNotifier<AppUser?> {
  CurrentProfileNotifier(AppUser? profile) : super(profile);

  void setProfile(AppUser profile) => state = profile;
  void clearProfile() => state = null;

  UserRole get role => state?.role ?? UserRole.customer;
  bool get isLoggedIn => state != null;
}

final authWatcherProvider = Provider<void>((ref) {
  final sub = FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user == null) {
      ref.read(currentProfileProvider.notifier).clearProfile();
    }
  });
  ref.onDispose(sub.cancel);
});

class OnboardingSeenNotifier extends StateNotifier<bool> {
  OnboardingSeenNotifier(this._prefs)
      : super(_prefs.getBool(AppConstants.onboardingSeenKey) ?? false);

  final SharedPreferences _prefs;

  Future<void> markSeen() async {
    await _prefs.setBool(AppConstants.onboardingSeenKey, true);
    state = true;
  }
}

final onboardingSeenProvider =
    StateNotifierProvider<OnboardingSeenNotifier, bool>(
  (ref) => OnboardingSeenNotifier(ref.read(sharedPreferencesProvider)),
);

Future<void> markOnboardingSeen(WidgetRef ref) async {
  await ref.read(onboardingSeenProvider.notifier).markSeen();
}
