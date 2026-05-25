import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/user_roles.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/customer/home/presentation/customer_shell.dart';
import '../features/customer/home/presentation/home_screen.dart';
import '../features/customer/profile/presentation/profile_screen.dart';
import '../features/customer/queue/presentation/live_queue_screen.dart';
import '../features/customer/queue/presentation/queue_request_screen.dart';
import '../features/customer/shop/presentation/shop_detail_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/owner/dashboard/presentation/owner_dashboard_screen.dart';
import '../features/owner/queue/presentation/owner_queue_screen.dart';
import '../features/owner/shop/presentation/shop_registration_screen.dart';
import '../providers/simple_auth.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const customerHome = '/customer';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const ownerDashboard = '/owner';
  static const shopRegistration = '/owner/register-shop';
  static const liveQueue = '/queue/:requestId';
  static const adminDashboard = '/admin';
}

String homeRouteForRole(UserRole role) {
  return switch (role) {
    UserRole.shopOwner => AppRoutes.ownerDashboard,
    UserRole.admin => AppRoutes.adminDashboard,
    UserRole.customer => AppRoutes.customerHome,
  };
}

// Separate notifier so router is NOT recreated on profile change
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(currentProfileProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingSeenProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  bool get onboardingSeen => _ref.read(onboardingSeenProvider);
  bool get loggedIn => _ref.read(currentProfileProvider) != null;
  UserRole? get role => _ref.read(currentProfileProvider)?.role;
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

final simpleRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  // Watch auth changes
  ref.watch(authWatcherProvider);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final loggedIn = notifier.loggedIn;
      final onboardingSeen = notifier.onboardingSeen;

      final isPublic = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.onboarding,
      ].contains(loc);

      if (!onboardingSeen && loc != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }

      if (!loggedIn && !isPublic) return AppRoutes.login;

      if (loggedIn && isPublic) {
        return homeRouteForRole(notifier.role!);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const _SplashRedirector(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.customerHome,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/shop/:shopId',
        builder: (_, state) =>
            ShopDetailScreen(shopId: state.pathParameters['shopId']!),
      ),
      GoRoute(
        path: '/shop/:shopId/request',
        builder: (_, state) =>
            QueueRequestScreen(shopId: state.pathParameters['shopId']!),
      ),
      GoRoute(
        path: AppRoutes.liveQueue,
        builder: (_, state) =>
            LiveQueueScreen(requestId: state.pathParameters['requestId']!),
      ),
      GoRoute(
        path: AppRoutes.ownerDashboard,
        builder: (_, __) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        path: '/owner/queue/:shopId',
        builder: (_, state) =>
            OwnerQueueScreen(shopId: state.pathParameters['shopId']!),
      ),
      GoRoute(
        path: AppRoutes.shopRegistration,
        builder: (_, __) => const ShopRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

class _SplashRedirector extends ConsumerStatefulWidget {
  const _SplashRedirector();

  @override
  ConsumerState<_SplashRedirector> createState() => _SplashRedirectorState();
}

class _SplashRedirectorState extends ConsumerState<_SplashRedirector> {
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      final profile = ref.read(currentProfileProvider);
      if (profile == null &&
          GoRouterState.of(context).matchedLocation == '/') {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.queue_play_next_rounded,
                  size: 72, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'NexQ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}