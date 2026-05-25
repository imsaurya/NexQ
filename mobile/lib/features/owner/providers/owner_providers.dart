import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/active_token.dart';
import '../../../models/queue_request.dart';
import '../../../models/shop.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/simple_auth.dart';

final ownerShopsProvider = FutureProvider<List<Shop>>((ref) async {
  final user = ref.watch(currentProfileProvider);
  if (user == null) return [];
  return ref.watch(shopRepositoryProvider).getOwnerShops(user.id);
});

final shopRequestsProvider =
    StreamProvider.family<List<QueueRequest>, String>((ref, shopId) {
  return ref.watch(queueEngineProvider).watchShopRequests(shopId);
});

final activeTokensProvider =
    StreamProvider.family<List<ActiveToken>, String>((ref, shopId) {
  return ref.watch(queueEngineProvider).watchActiveTokens(shopId);
});
