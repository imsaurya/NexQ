import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/app_user.dart';
import '../../../providers/auth_provider.dart';

/// Register auth side-effects inside [build] (valid Riverpod listener scope).
/// Navigation after sign-in is handled by [GoRouter] redirect — not here.
void listenAuthController(WidgetRef ref, BuildContext context) {
  ref.listen<AsyncValue<AppUser?>>(authControllerProvider, (previous, next) {
    if (!context.mounted) return;

    next.whenOrNull(
      error: (error, _) {
        final message =
            error is AppException ? error.message : error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  });
}
