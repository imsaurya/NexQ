import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../models/shop.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/simple_auth.dart';
import '../../../../widgets/common/app_widgets.dart';
import '../../shop/presentation/shop_detail_screen.dart';

class QueueRequestScreen extends ConsumerStatefulWidget {
  const QueueRequestScreen({super.key, required this.shopId});

  final String shopId;

  @override
  ConsumerState<QueueRequestScreen> createState() => _QueueRequestScreenState();
}

class _QueueRequestScreenState extends ConsumerState<QueueRequestScreen> {
  ShopService? _selectedService;
  String? _preferredTime;
  final _noteController = TextEditingController();
  bool _submitting = false;

  final _timeSlots = const [
    'ASAP',
    'Morning (9-12)',
    'Afternoon (12-5)',
    'Evening (5-9)',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit(Shop shop) async {
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service')),
      );
      return;
    }

    final user = ref.read(currentProfileProvider);
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      final request = await ref.read(queueEngineProvider).submitRequest(
            shopId: widget.shopId,
            customerId: user.id,
            customerName: user.displayName,
            serviceId: _selectedService!.id,
            serviceName: _selectedService!.name,
            preferredTime: _preferredTime,
            note: _noteController.text.isEmpty ? null : _noteController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted! Waiting for approval.')),
        );
        context.go('/queue/${request.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(shopDetailProvider(widget.shopId));

    return Scaffold(
      appBar: AppBar(title: const Text('Request Queue Spot')),
      body: shopAsync.when(
        data: (shop) {
          if (shop == null) return const Center(child: Text('Shop not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Service', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...shop.services.map(
                  (s) => RadioListTile<ShopService>(
                    value: s,
                    groupValue: _selectedService,
                    onChanged: (v) => setState(() => _selectedService = v),
                    title: Text(s.name),
                    subtitle: Text('${s.durationMinutes} min • ₹${s.price.toStringAsFixed(0)}'),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Preferred Time', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _timeSlots
                      .map(
                        (t) => ChoiceChip(
                          label: Text(t),
                          selected: _preferredTime == t,
                          onSelected: (_) => setState(() => _preferredTime = t),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _noteController,
                  label: 'Note (optional)',
                  hint: 'Any special request...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Submit Request',
                  isLoading: _submitting,
                  onPressed: () => _submit(shop),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
