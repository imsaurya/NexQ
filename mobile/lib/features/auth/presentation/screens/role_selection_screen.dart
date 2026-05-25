import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/simple_router.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Experience')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _RoleCard(
              icon: Icons.person,
              title: 'Customer',
              subtitle: 'Browse shops and join queues',
              onTap: () => context.go(AppRoutes.customerHome),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              icon: Icons.store,
              title: 'Shop Owner',
              subtitle: 'Manage your shop queue',
              onTap: () => context.go(AppRoutes.ownerDashboard),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                child: Icon(icon, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
