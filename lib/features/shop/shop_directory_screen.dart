import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/app_scaffold.dart';

class ShopDirectoryScreen extends StatelessWidget {
  const ShopDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Shop',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/listing/create'),
        label: const Text('Create Listing'),
        icon: const Icon(Icons.add),
      ),
      body: ListView(
        children: [
          const Text('Shop listings (placeholder for Day 5).'),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Open example listing detail'),
            subtitle: const Text('Route: /listing/example_listing_id'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/listing/example_listing_id'),
          ),
        ],
      ),
    );
  }
}
