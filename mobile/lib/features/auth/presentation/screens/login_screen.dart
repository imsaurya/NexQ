import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/simple_auth.dart';
import '../../../../routes/simple_router.dart';
import '../../../../widgets/common/app_widgets.dart';
import '../auth_screen_listeners.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final appUser = await ref.read(authControllerProvider.notifier).signInWithEmail(
            _emailController.text,
            _passwordController.text,
          );
      ref.read(currentProfileProvider.notifier).setProfile(appUser);
    } catch (_) {
      // Error shown via listenAuthController.
    }
  }

  Future<void> _googleLogin() async {
    try {
      final appUser =
          await ref.read(authControllerProvider.notifier).signInWithGoogle();
      ref.read(currentProfileProvider.notifier).setProfile(appUser);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    listenAuthController(ref, context);

    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isBusy = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  'Welcome to ${AppConstants.appName}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to manage your queues',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isBusy
                        ? null
                        : () => context.push(AppRoutes.forgotPassword),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: isBusy ? 'Signing in...' : 'Sign In',
                  isLoading: isBusy,
                  onPressed: isBusy ? null : _login,
                ),
                const SizedBox(height: 16),
                SecondaryButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata,
                  onPressed: isBusy ? () {} : _googleLogin,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: isBusy ? null : () => context.push(AppRoutes.register),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
