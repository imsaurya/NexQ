import '../../../../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../models/queue_request.dart';
import '../../../../models/shop.dart';
import '../../../../providers/app_providers.dart';
import '../../providers/owner_providers.dart';
import '../../../../routes/simple_router.dart';
import '../../../../providers/simple_auth.dart';
import '../../../../widgets/common/app_widgets.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(ownerShopsProvider);
    final user = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
  title: const Text('Owner Dashboard'),
  actions: [
    IconButton(
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () => context.push('/notifications'),
    ),
    IconButton(
      icon: const Icon(Icons.person_outline),
      onPressed: () => context.push('/profile'),
    ),
    IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Sign Out',
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        );
       if (confirm == true && context.mounted) {
  ref.read(authControllerProvider.notifier).signOut();
}
      },
    ),
  ],
),
      body: shopsAsync.when(
        data: (shops) {
          if (shops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No shops registered yet'),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Register Shop',
                    onPressed: () => context.push(AppRoutes.shopRegistration),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shops.length,
            itemBuilder: (_, i) => _OwnerShopCard(shop: shops[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: user != null
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.shopRegistration),
              icon: const Icon(Icons.add),
              label: const Text('Add Shop'),
            )
          : null,
    );
  }
}

class _OwnerShopCard extends ConsumerWidget {
  const _OwnerShopCard({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(shopRequestsProvider(shop.id));
    final pending = requestsAsync.valueOrNull
            ?.where((r) => r.status == QueueRequestStatus.pending)
            .length ??
        0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/owner/queue/${shop.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shop.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StatusChip(
                    label: shop.approvalStatus.name,
                    color: shop.approvalStatus.name == 'approved'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ],
              ),
              Text('${shop.area}, ${shop.city}'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MiniStat(label: 'Waiting', value: '${shop.waitingCount}'),
                  _MiniStat(label: 'Serving', value: '#${shop.servingToken}'),
                  _MiniStat(label: 'Pending', value: '$pending'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final status = shop.status == ShopStatus.open
                            ? ShopStatus.closed
                            : ShopStatus.open;
                        await ref
                            .read(shopRepositoryProvider)
                            .updateShopStatus(shop.id, status);
                      },
                      child: Text(shop.status == ShopStatus.open ? 'Close' : 'Open'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.push('/owner/queue/${shop.id}'),
                      child: const Text('Manage Queue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
