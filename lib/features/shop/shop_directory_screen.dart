import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/empty_state_view.dart';
import '../../core/ui/error_state_view.dart';
import '../../core/ui/loading_view.dart';
import '../../di/providers.dart';
import '../../domain/models/shop_listing.dart';

final _listingsProvider = FutureProvider.autoDispose<List<ShopListing>>((ref) {
  return ref.watch(listingRepositoryProvider).listListings(limit: 20);
});

class ShopDirectoryScreen extends ConsumerWidget {
  const ShopDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final listingsAsync = ref.watch(_listingsProvider);

    return AppScaffold(
      title: 'Shop',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/listing/create'),
        label: const Text('Create Listing'),
        icon: const Icon(Icons.add),
      ),
    body: listingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) {
          return const EmptyStateView(message: 'No listings found.');
        }

        return ListView(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Shop listings (Day 2: repo read sanity check).'),
            ),
            for (final listing in listings)
              ListTile(
                title: Text(listing.bikeTitle),
                subtitle: Text(
                  '${listing.brandLabel} · ${listing.category} · ${listing.displacementBucket}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/listing/${listing.id}'),
              ),
          ],
        );
      },
      error: (error, _) => ErrorStateView(
        message: 'Failed to load listings.',
        onRetry: () => ref.invalidate(_listingsProvider),
      ),
      loading: () => const LoadingView(message: 'Loading listings…'),
    ),
    );
  }
}
