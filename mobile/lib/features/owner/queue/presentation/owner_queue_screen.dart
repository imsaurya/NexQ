import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/active_token.dart';
import '../../../../models/queue_request.dart';
import '../../../../models/shop.dart';
import '../../../../providers/app_providers.dart';
import '../../../../widgets/common/app_widgets.dart';
import '../../providers/owner_providers.dart';
import '../../../customer/shop/presentation/shop_detail_screen.dart';

class OwnerQueueScreen extends ConsumerWidget {
  const OwnerQueueScreen({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopDetailProvider(shopId));
    final requestsAsync = ref.watch(shopRequestsProvider(shopId));
    final tokensAsync = ref.watch(activeTokensProvider(shopId));

    return Scaffold(
      appBar: AppBar(title: const Text('Queue Management')),
      body: shopAsync.when(
        data: (shop) {
          if (shop == null) return const Center(child: Text('Shop not found'));

          return Column(
            children: [
              _ServingHeader(shop: shop),
              _QueueControls(shop: shop),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Pending'),
                          Tab(text: 'Active Tokens'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _PendingList(
                              requests: requestsAsync.valueOrNull ?? [],
                              shopId: shopId,
                            ),
                            _TokenList(
                              tokens: tokensAsync.valueOrNull ?? [],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ServingHeader extends StatelessWidget {
  const _ServingHeader({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        children: [
          Text('Now Serving', style: Theme.of(context).textTheme.titleSmall),
          Text(
            '#${shop.servingToken}',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          Text('${shop.waitingCount} customers waiting'),
        ],
      ),
    );
  }
}

class _QueueControls extends ConsumerWidget {
  const _QueueControls({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(queueEngineProvider);
    final shopRepo = ref.read(shopRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _ActionChip(
            label: 'Next Token',
            icon: Icons.skip_next,
            onPressed: () => engine.nextToken(shop.id),
          ),
          _ActionChip(
            label: 'Skip',
            icon: Icons.fast_forward,
            onPressed: () => engine.skipToken(shop.id),
          ),
          _ActionChip(
            label: shop.queuePaused ? 'Resume' : 'Pause',
            icon: shop.queuePaused ? Icons.play_arrow : Icons.pause,
            onPressed: () =>
                shopRepo.setQueuePaused(shop.id, !shop.queuePaused),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

class _PendingList extends ConsumerWidget {
  const _PendingList({required this.requests, required this.shopId});

  final List<QueueRequest> requests;
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending =
        requests.where((r) => r.status == QueueRequestStatus.pending).toList();

    if (pending.isEmpty) {
      return const Center(child: Text('No pending requests'));
    }

    final engine = ref.read(queueEngineProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (_, i) {
        final r = pending[i];
        return Card(
          child: ListTile(
            title: Text(r.customerName),
            subtitle: Text('${r.serviceName}${r.note != null ? " • ${r.note}" : ""}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => engine.approveRequest(r.id),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => engine.rejectRequest(r.id),
                ),
                IconButton(
                  icon: const Icon(Icons.schedule, color: Colors.orange),
                  onPressed: () => engine.delayRequest(r.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TokenList extends StatelessWidget {
  const _TokenList({required this.tokens});

  final List<ActiveToken> tokens;

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return const Center(child: Text('No active tokens'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tokens.length,
      itemBuilder: (_, i) {
        final t = tokens[i];
        return ListTile(
          leading: CircleAvatar(child: Text('${t.tokenNumber}')),
          title: Text(t.customerName),
          subtitle: Text(t.serviceName),
          trailing: t.isServing
              ? const StatusChip(label: 'Serving', color: Colors.green)
              : t.isDelayed
                  ? const StatusChip(label: 'Delayed', color: Colors.orange)
                  : null,
        );
      },
    );
  }
}
