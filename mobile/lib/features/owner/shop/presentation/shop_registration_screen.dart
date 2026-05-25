import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../features/customer/home/presentation/home_screen.dart';
import '../../../../features/owner/providers/owner_providers.dart';
import '../../../../models/shop.dart';
import '../../../../providers/app_providers.dart';
import '../../../../providers/simple_auth.dart';
import '../../../../widgets/common/app_widgets.dart';

class ShopRegistrationScreen extends ConsumerStatefulWidget {
  const ShopRegistrationScreen({super.key});

  @override
  ConsumerState<ShopRegistrationScreen> createState() =>
      _ShopRegistrationScreenState();
}

class _ShopRegistrationScreenState extends ConsumerState<ShopRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _openController = TextEditingController(text: '09:00');
  final _closeController = TextEditingController(text: '21:00');

  String _city = AppConstants.defaultCities.first;
  String _area = AppConstants.cityAreas[AppConstants.defaultCities.first]!.first;
  String _categoryId = 'salon';
  String _categoryName = 'Salon';
  bool _submitting = false;

  final _services = <ShopService>[];
  final _serviceNameController = TextEditingController();
  final _serviceDurationController = TextEditingController(text: '15');
  final _servicePriceController = TextEditingController(text: '0');

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _openController.dispose();
    _closeController.dispose();
    _serviceNameController.dispose();
    _serviceDurationController.dispose();
    _servicePriceController.dispose();
    super.dispose();
  }

  void _addService() {
    if (_serviceNameController.text.isEmpty) return;
    setState(() {
      _services.add(ShopService(
        id: const Uuid().v4(),
        name: _serviceNameController.text,
        durationMinutes: int.tryParse(_serviceDurationController.text) ?? 15,
        price: double.tryParse(_servicePriceController.text) ?? 0,
      ));
      _serviceNameController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one service')),
      );
      return;
    }

    final user = ref.read(currentProfileProvider);
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(shopRepositoryProvider).createShop(
            ownerId: user.id,
            name: _nameController.text.trim(),
            categoryId: _categoryId,
            categoryName: _categoryName,
            city: _city,
            area: _area,
            address: _addressController.text.trim(),
            timings: ShopTimings(
              openTime: _openController.text,
              closeTime: _closeController.text,
              workingDays: const [1, 2, 3, 4, 5, 6],
            ),
            services: _services,
          );
      ref.invalidate(ownerShopsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop submitted for approval')),
        );
        context.pop();
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
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Register Shop')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Shop Name',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            categories.when(
              data: (cats) => DropdownButtonFormField<String>(
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: cats
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  final cat = cats.firstWhere((c) => c.id == v);
                  setState(() {
                    _categoryId = cat.id;
                    _categoryName = cat.name;
                  });
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _city,
              decoration: const InputDecoration(labelText: 'City'),
              items: AppConstants.defaultCities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _city = v;
                  _area = AppConstants.cityAreas[v]!.first;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _area,
              decoration: const InputDecoration(labelText: 'Area'),
              items: (AppConstants.cityAreas[_city] ?? [])
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _area = v ?? _area),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _addressController,
              label: 'Address',
              maxLines: 2,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(controller: _openController, label: 'Open'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(controller: _closeController, label: 'Close'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Services', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _serviceNameController,
                    decoration: const InputDecoration(hintText: 'Service name'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _serviceDurationController,
                    decoration: const InputDecoration(hintText: 'Min'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _servicePriceController,
                    decoration: const InputDecoration(hintText: '₹'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(onPressed: _addService, icon: const Icon(Icons.add)),
              ],
            ),
            ..._services.map(
              (s) => ListTile(
                title: Text(s.name),
                subtitle: Text('${s.durationMinutes} min'),
                trailing: Text('₹${s.price.toStringAsFixed(0)}'),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Submit for Approval',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
