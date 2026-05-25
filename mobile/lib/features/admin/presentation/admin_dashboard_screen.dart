import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/auth_provider.dart';

import '../../../../providers/app_providers.dart';
import '../../../../models/shop.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pendingShops = ref.watch(_pendingShopsProvider);
    final allShops = ref.watch(_allShopsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: theme.colorScheme.errorContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats
          Row(children: [
            _statCard(context, 'Pending', Icons.pending_outlined,
                Colors.orange,
                pendingShops.valueOrNull?.length.toString() ?? '...'),
            const SizedBox(width: 12),
            _statCard(context, 'All Shops', Icons.storefront_outlined,
                Colors.blue,
                allShops.valueOrNull?.length.toString() ?? '...'),
          ]),
          const SizedBox(height: 24),
          Text('Pending Approval',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          pendingShops.when(
            data: (shops) => shops.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No shops pending approval'),
                    ))
                : Column(
                    children: shops
                        .map((s) => _ShopApprovalCard(shop: s))
                        .toList()),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 24),
          Text('All Shops',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          allShops.when(
            data: (shops) => Column(
                children: shops.map((s) => _ShopManageCard(shop: s)).toList()),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, IconData icon,
      Color color, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title,
              style: TextStyle(fontSize: 12, color: color),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

final _pendingShopsProvider = StreamProvider<List<Shop>>((ref) {
  return ref.read(shopRepositoryProvider).watchShopsByStatus('pending');
});

final _allShopsProvider = StreamProvider<List<Shop>>((ref) {
  return ref.read(shopRepositoryProvider).watchAllShops();
});

class _ShopApprovalCard extends ConsumerWidget {
  const _ShopApprovalCard({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(shop.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('${shop.area}, ${shop.city}',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ref
                    .read(shopRepositoryProvider)
                    .updateShopApproval(shop.id, 'rejected'),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => ref
                    .read(shopRepositoryProvider)
                    .updateShopApproval(shop.id, 'approved'),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _ShopManageCard extends ConsumerWidget {
  const _ShopManageCard({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = switch (shop.approvalStatus.name) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      'banned' => Colors.black,
      _ => Colors.orange,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(shop.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${shop.area}, ${shop.city}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(shop.approvalStatus.name,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          if (shop.approvalStatus.name != 'banned')
            IconButton(
              icon: const Icon(Icons.block, color: Colors.red),
              tooltip: 'Ban shop',
              onPressed: () => ref
                  .read(shopRepositoryProvider)
                  .updateShopApproval(shop.id, 'banned'),
            ),
        ]),
      ),
    );
  }
}
