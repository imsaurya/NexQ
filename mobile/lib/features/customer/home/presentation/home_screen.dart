import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/category.dart';
import '../../../../models/shop.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/simple_auth.dart';
import '../../../../theme/theme_provider.dart';
import '../../../../widgets/common/app_widgets.dart';
import '../../../../widgets/loading/shimmer_widgets.dart';

final selectedCityProvider = StateNotifierProvider<CityFilterNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CityFilterNotifier(prefs);
});

final selectedAreaProvider = StateProvider<String?>((ref) => null);
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

class CityFilterNotifier extends StateNotifier<String> {
  CityFilterNotifier(this._prefs)
      : super(_prefs.getString(AppConstants.selectedCityKey) ??
            AppConstants.defaultCities.first);

  final SharedPreferences _prefs;

  Future<void> setCity(String city) async {
    state = city;
    await _prefs.setString(AppConstants.selectedCityKey, city);
  }
}

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null) {
    return const Stream.empty();
  }
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

final shopsProvider = StreamProvider<List<Shop>>((ref) {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null) {
    return const Stream.empty();
  }

  final city = ref.watch(selectedCityProvider);
  final area = ref.watch(selectedAreaProvider);
  final categoryId = ref.watch(selectedCategoryProvider);
  final search = ref.watch(searchQueryProvider);

  return ref.watch(shopRepositoryProvider).watchShops(
        city: city,
        area: area,
        categoryId: categoryId,
        searchQuery: search,
      );
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _iconForCategory(String iconName) {
    return switch (iconName) {
      'content_cut' => Icons.content_cut,
      'medical_services' => Icons.medical_services,
      'local_cafe' => Icons.local_cafe,
      'build' => Icons.build,
      'handyman' => Icons.handyman,
      'account_balance' => Icons.account_balance,
      _ => Icons.store,
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentProfileProvider, (previous, next) {
      if (next != null && previous == null) {
        ref.read(categoryRepositoryProvider).seedDefaultCategories();
      }
    });

    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final selectedCity = ref.watch(selectedCityProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final shopsAsync = ref.watch(shopsProvider);
    final areas = AppConstants.cityAreas[selectedCity] ?? [];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(shopsProvider);
          ref.invalidate(categoriesProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NexQ',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    selectedCity,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.location_city),
                  onPressed: () => _showCityPicker(context),
                  tooltip: 'Change city',
                ),
                IconButton(
                  icon: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search shops or areas...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) =>
                      ref.read(searchQueryProvider.notifier).state = v,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: selectedCity,
                      icon: Icons.location_city,
                      onTap: () => _showCityPicker(context),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: ref.watch(selectedAreaProvider) ?? 'All Areas',
                      icon: Icons.place_outlined,
                      onTap: () => _showAreaPicker(context, areas),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Categories', style: theme.textTheme.titleMedium),
              ),
            ),
            categoriesAsync.when(
              data: (categories) => SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView.builder(
                    clipBehavior: Clip.hardEdge,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        final selected =
                            ref.watch(selectedCategoryProvider) == null;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _CategoryCard(
                            label: 'All',
                            icon: Icons.apps,
                            selected: selected,
                            onTap: () => ref
                                .read(selectedCategoryProvider.notifier)
                                .state = null,
                          ),
                        );
                      }
                      final cat = categories[i - 1];
                      final selected =
                          ref.watch(selectedCategoryProvider) == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CategoryCard(
                          label: cat.name,
                          icon: _iconForCategory(cat.iconName),
                          selected: selected,
                          onTap: () => ref
                              .read(selectedCategoryProvider.notifier)
                              .state = cat.id,
                        ),
                      );
                    },
                  ),
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Nearby Shops', style: theme.textTheme.titleMedium),
              ),
            ),
            shopsAsync.when(
              data: (shops) {
                if (shops.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No shops found in this area')),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ShopCard(shop: shops[i]),
                    ),
                    childCount: shops.length,
                  ),
                );
              },
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ShopCardShimmer(),
                  ),
                  childCount: 4,
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorBanner(message: e.toString()),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Future<void> _showCityPicker(BuildContext context) async {
    final city = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => ListView(
        children: AppConstants.defaultCities
            .map((c) => ListTile(title: Text(c), onTap: () => Navigator.pop(ctx, c)))
            .toList(),
      ),
    );
    if (city != null) {
      await ref.read(selectedCityProvider.notifier).setCity(city);
      ref.read(selectedAreaProvider.notifier).state = null;
    }
  }

  Future<void> _showAreaPicker(BuildContext context, List<String> areas) async {
    final area = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          ListTile(
            title: const Text('All Areas'),
            onTap: () => Navigator.pop(ctx, ''),
          ),
          ...areas.map(
            (a) => ListTile(title: Text(a), onTap: () => Navigator.pop(ctx, a)),
          ),
        ],
      ),
    );
    if (area != null) {
      ref.read(selectedAreaProvider.notifier).state =
          area.isEmpty ? null : area;
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.none,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = shop.status.name == 'open' && !shop.queuePaused;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/shop/${shop.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: shop.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: shop.imageUrls.first,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.storefront,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${shop.area} • ${shop.city}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        color: isOpen ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${shop.servingToken} serving • ${shop.waitingCount} waiting',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '~${shop.avgWaitMinutes} min wait',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
