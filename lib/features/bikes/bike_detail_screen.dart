import 'package:flutter/material.dart';

import '../../core/ui/app_scaffold.dart';

class BikeDetailScreen extends StatelessWidget {
  const BikeDetailScreen({super.key, required this.bikeId});

  final String bikeId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Bike Detail',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('bikeId: $bikeId'),
          const SizedBox(height: 12),
          const Text('Placeholder — implement specs + SEA notes + comments on Day 3.'),
        ],
      ),
    );
  }
}
