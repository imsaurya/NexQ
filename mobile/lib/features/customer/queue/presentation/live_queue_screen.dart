import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/queue_request.dart';
import '../../queue/presentation/queue_providers.dart';
import '../../../../models/shop.dart';
import '../../../../providers/app_providers.dart';
import '../../../../widgets/common/app_widgets.dart';
import '../../shop/presentation/shop_detail_screen.dart';

class LiveQueueScreen extends ConsumerWidget {
  const LiveQueueScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(queueRequestProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Live Queue')),
      body: requestAsync.when(
        data: (request) {
          if (request == null) {
            return const Center(child: Text('Queue request not found'));
          }
          final shopAsync = ref.watch(shopDetailProvider(request.shopId));

          return shopAsync.when(
            data: (shop) => _LiveQueueBody(
              request: request,
              shop: shop,
              onCancel: () async {
                await ref.read(queueEngineProvider).cancelRequest(requestId);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _LiveQueueBody extends StatelessWidget {
  const _LiveQueueBody({
    required this.request,
    required this.shop,
    required this.onCancel,
  });

  final QueueRequest request;
  final Shop? shop;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serving = shop?.servingToken ?? 0;
    final myToken = request.tokenNumber;
    final peopleAhead =
        myToken != null ? (myToken - serving - 1).clamp(0, 999) : request.peopleAhead;
    final paused = shop?.queuePaused ?? false;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          StatusChip(
            label: request.status.name.toUpperCase(),
            color: switch (request.status) {
              QueueRequestStatus.approved => Colors.green,
              QueueRequestStatus.pending => Colors.orange,
              QueueRequestStatus.delayed => Colors.amber,
              QueueRequestStatus.rejected => Colors.red,
              QueueRequestStatus.cancelled => Colors.grey,
              QueueRequestStatus.completed => Colors.blue,
            },
          ),
          const SizedBox(height: 32),
          if (myToken != null) ...[
            Text('Your Token', style: theme.textTheme.titleMedium),
            Text(
              '#$myToken',
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            _ProgressRing(
              progress: serving > 0 && myToken > serving
                  ? (serving / myToken).clamp(0.0, 1.0)
                  : 0.1,
            ),
            const SizedBox(height: 24),
            Text('Currently Serving: #$serving'),
            Text('People Ahead: $peopleAhead'),
            Text('Est. Wait: ~${shop?.avgWaitMinutes ?? 15} min'),
          ] else ...[
            const Icon(Icons.hourglass_top, size: 64),
            const SizedBox(height: 16),
            Text('Waiting for shop approval', style: theme.textTheme.titleMedium),
            Text('Service: ${request.serviceName}'),
          ],
          if (paused) ...[
            const SizedBox(height: 16),
            const StatusChip(label: 'Queue Paused', color: Colors.orange),
          ],
          const Spacer(),
          if (request.isActive)
            SecondaryButton(label: 'Cancel Request', onPressed: onCancel),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(value: progress, strokeWidth: 10),
          Text('${(progress * 100).toInt()}%'),
        ],
      ),
    );
  }
}
