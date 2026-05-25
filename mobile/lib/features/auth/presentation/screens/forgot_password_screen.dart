import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../widgets/common/app_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_emailController.text);
    if (mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email and we will send a reset link.',
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 24),
            if (_sent)
              const ErrorBanner(
                message: 'Reset link sent! Check your inbox.',
              ),
            if (!_sent)
              PrimaryButton(
                label: 'Send Reset Link',
                isLoading: authState.isLoading,
                onPressed: _reset,
              ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Back to login'),
            ),
          ],
        ),
      ),
    );
  }
}
