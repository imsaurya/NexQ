import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../models/review.dart';
import '../../../../models/shop.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/simple_auth.dart';
import '../../../../widgets/common/app_widgets.dart';

final shopDetailProvider = StreamProvider.family<Shop?, String>((ref, shopId) {
  return ref.watch(shopRepositoryProvider).watchShop(shopId);
});

final shopReviewsProvider = StreamProvider.family<List<Review>, String>((ref, shopId) {
  return ref.watch(reviewRepositoryProvider).watchShopReviews(shopId);
});

class ShopDetailScreen extends ConsumerWidget {
  const ShopDetailScreen({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopDetailProvider(shopId));
    final reviewsAsync = ref.watch(shopReviewsProvider(shopId));
    final user = ref.watch(currentProfileProvider);

    return Scaffold(
      body: shopAsync.when(
        data: (shop) {
          if (shop == null) {
            return const Center(child: Text('Shop not found'));
          }
          return _ShopDetailBody(
            shop: shop,
            reviewsAsync: reviewsAsync,
            isSaved: user?.savedShopIds.contains(shopId) ?? false,
            onSave: () async {
              if (user == null) return;
              await ref.read(userRepositoryProvider).toggleSavedShop(user.id, shopId);
            },
            onShare: () => Share.share('Check out ${shop.name} on NexQ!'),
            onNavigate: () => _openMaps(shop.address, shop.city),
            onRequestQueue: () => context.push('/shop/$shopId/request'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _openMaps(String address, String city) async {
    final query = Uri.encodeComponent('$address, $city');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ShopDetailBody extends StatelessWidget {
  const _ShopDetailBody({
    required this.shop,
    required this.reviewsAsync,
    required this.isSaved,
    required this.onSave,
    required this.onShare,
    required this.onNavigate,
    required this.onRequestQueue,
  });

  final Shop shop;
  final AsyncValue<List<Review>> reviewsAsync;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onNavigate;
  final VoidCallback onRequestQueue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = shop.status == ShopStatus.open && !shop.queuePaused;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(shop.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            background: shop.imageUrls.isNotEmpty
                ? CachedNetworkImage(imageUrl: shop.imageUrls.first, fit: BoxFit.cover)
                : Container(color: theme.colorScheme.primaryContainer),
          ),
          actions: [
            IconButton(
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline),
              onPressed: onSave,
            ),
            IconButton(icon: const Icon(Icons.share), onPressed: onShare),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(
                      label: isOpen ? 'Open' : shop.queuePaused ? 'Paused' : 'Closed',
                      color: isOpen ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    CrowdBadge(level: shop.crowdLevel),
                    const Spacer(),
                    if (shop.rating > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          Text('${shop.rating.toStringAsFixed(1)} (${shop.reviewCount})'),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${shop.categoryName} • ${shop.area}, ${shop.city}'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onNavigate,
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(shop.address)),
                      const Icon(Icons.open_in_new, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Hours: ${shop.timings.openTime} - ${shop.timings.closeTime}'),
                const SizedBox(height: 20),
                _QueueStatsCard(shop: shop),
                const SizedBox(height: 20),
                Text('Services', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...shop.services.map(
                  (s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.name),
                    subtitle: Text('${s.durationMinutes} min'),
                    trailing: Text('₹${s.price.toStringAsFixed(0)}'),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Reviews', style: theme.textTheme.titleMedium),
                reviewsAsync.when(
                  data: (reviews) {
                    if (reviews.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No reviews yet'),
                      );
                    }
                    return Column(
                      children: reviews
                          .map(
                            (r) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(r.userName),
                              subtitle: Text(r.comment),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.amber),
                                  Text(r.rating.toString()),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            label: isOpen ? 'Request Queue Spot' : 'Shop Not Accepting Queue',
            onPressed: isOpen ? onRequestQueue : null,
          ),
        ),
      ),
    );
  }
}

class _QueueStatsCard extends StatelessWidget {
  const _QueueStatsCard({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(label: 'Serving', value: '#${shop.servingToken}'),
            _StatItem(label: 'Waiting', value: '${shop.waitingCount}'),
            _StatItem(label: 'Est. Wait', value: '~${shop.avgWaitMinutes}m'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
