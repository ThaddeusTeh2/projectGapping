import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/app_scaffold.dart';

class BikeDirectoryScreen extends StatelessWidget {
  const BikeDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Bikes',
      body: ListView(
        children: [
          const Text('Bike directory (placeholder for Day 3).'),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Open example bike detail'),
            subtitle: const Text('Route: /bike/example_bike_id'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/bike/example_bike_id'),
          ),
        ],
      ),
    );
  }
}
