import 'package:flutter/material.dart';

import '../../core/ui/app_scaffold.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Listing Detail',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('listingId: $listingId'),
          const SizedBox(height: 12),
          const Text('Placeholder — implement listing info + bid UI on Day 5.'),
        ],
      ),
    );
  }
}
