import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/simple_auth.dart';
import '../../../../routes/simple_router.dart';
import '../../../../widgets/common/app_widgets.dart';
import '../auth_screen_listeners.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.customer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final appUser = await ref.read(authControllerProvider.notifier).signUpWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _nameController.text,
            role: _role,
          );
      ref.read(currentProfileProvider.notifier).setProfile(appUser);
    } catch (_) {
      // Error shown via listenAuthController.
    }
  }

  @override
  Widget build(BuildContext context) {
    listenAuthController(ref, context);

    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isBusy = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || !v.contains('@')) {
                      return 'Valid email required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : 'Min 6 characters',
                ),
                const SizedBox(height: 20),
                Text('I am a', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(
                      value: UserRole.customer,
                      label: Text('Customer'),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment(
                      value: UserRole.shopOwner,
                      label: Text('Shop Owner'),
                      icon: Icon(Icons.store),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) => setState(() => _role = s.first),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: isBusy ? 'Creating account...' : 'Create Account',
                  isLoading: isBusy,
                  onPressed: isBusy ? null : _register,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Sign In'),
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
