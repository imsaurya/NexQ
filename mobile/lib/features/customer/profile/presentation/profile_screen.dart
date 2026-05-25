import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../models/queue_request.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/simple_auth.dart';
import '../../../../routes/simple_router.dart';
import '../../../../theme/theme_provider.dart';
import '../../../../widgets/common/app_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentProfileProvider);
    final themeMode = ref.watch(themeModeProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: PrimaryButton(
            label: 'Sign In',
            onPressed: () => context.go(AppRoutes.login),
          ),
        ),
      );
    }

    final requestsAsync = ref.watch(_customerRequestsProvider(user.id));
    final activeQueues =
        requestsAsync.valueOrNull?.where((r) => r.isActive).toList() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage:
                    user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null
                    ? Text(user.displayName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(user.email),
                    Text(user.role.value.replaceAll('_', ' ')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
          ),
          if (user.role == UserRole.shopOwner)
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Owner Dashboard'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.ownerDashboard),
            ),
          ListTile(
            leading: const Icon(Icons.queue),
            title: Text('Active Queues (${activeQueues.length})'),
          ),
          ...activeQueues.map(
            (r) => ListTile(
              title: Text('Token #${r.tokenNumber ?? "Pending"}'),
              subtitle: Text('${r.serviceName} • ${r.status.name}'),
              onTap: () => context.push('/queue/${r.id}'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: Text('Saved Shops (${user.savedShopIds.length})'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Booking History'),
            subtitle: Text('${requestsAsync.valueOrNull?.length ?? 0} total'),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Support'),
            subtitle: const Text('support@nexq.app'),
          ),
          const SizedBox(height: 24),
          SecondaryButton(
            label: 'Sign Out',
            icon: Icons.logout,
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              ref.read(currentProfileProvider.notifier).clearProfile();
            },
          ),
        ],
      ),
    );
  }
}

final _customerRequestsProvider =
    StreamProvider.family<List<QueueRequest>, String>((ref, customerId) {
  return ref.watch(queueEngineProvider).watchCustomerRequests(customerId);
});
